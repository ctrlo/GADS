=pod
GADS - Globally Accessible Data Store
Copyright (C) 2014 Ctrl O Ltd

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=cut

package GADS::Column::Calc;

use Log::Report 'linkspace';

use Moo;
use MooX::Types::MooseLike::Base qw/:all/;
use Scalar::Util qw(looks_like_number);

extends 'GADS::Column::Code';

with 'GADS::DateTime';

has '+type' => (
    default => 'calc',
);

has '+option_names' => (
    default => sub { [qw/show_in_edit/] },
);

has show_in_edit => (
    is      => 'rw',
    isa     => Bool,
    lazy    => 1,
    coerce  => sub { $_[0] ? 1 : 0 },
    builder => sub {
        my $self = shift;
        return 0 unless $self->has_options;
        $self->options->{show_in_edit};
    },
    trigger => sub { $_[0]->reset_options },
);

has 'has_filter_typeahead' => (
    is      => 'lazy',
);

sub _build_sort_field
{   my $self = shift;
    return 'value_date_from' if $self->return_type eq 'daterange';
    $self->value_field;
}

# The from and to fields from the database table when used as a daterange
sub from_field { 'value_date_from' }
sub to_field { 'value_date_to' }

sub has_time
{   my $self = shift;
    $self->return_type eq 'daterange';
}

sub _build_has_filter_typeahead
{   my $self = shift;
    $self->value_field eq 'value_text' ? 1 : 0;
}

sub _build__rset_code
{   my $self = shift;
    $self->_rset or return;
    my ($code) = $self->_rset->calcs;
    if (!$code)
    {
        $code = $self->schema->resultset('Calc')->new({});
    }
    return $code;
}

after build_values => sub {
    my ($self, $original) = @_;
    my $calc = $original->{calcs}->[0];
    $self->return_type($calc->{return_format});
    $self->decimal_places($calc->{decimal_places});
};

# Convert return format to database column field
sub _format_to_field
{   my $return_type = shift;
    $return_type eq 'date'
    ? 'value_date'
    : $return_type eq 'daterange'
    ? 'value_text'
    : $return_type eq 'integer'
    ? 'value_int'
    : $return_type eq 'numeric'
    ? 'value_numeric'
    : 'value_text' # includes globe data type
}

has unique_key => (
    is      => 'ro',
    default => 'calcval_ux_record_layout',
);

has '+can_multivalue' => (
    default => 1,
);

# Used to provide a blank template for row insertion
# (to blank existing values)
has '+blank_row' => (
    lazy => 1,
    builder => sub {
        {
            value_date      => undef,
            value_int       => undef,
            value_numeric   => undef,
            value_text      => undef,
            value_date_from => undef,
            value_date_to   => undef,
        };
    },
);

has '+table' => (
    default => 'Calcval',
);

sub table_unique { "CalcUnique" }

has '+return_type' => (
    isa => sub {
        return unless $_[0];
        $_[0] =~ /(string|date|integer|numeric|globe|error|daterange)/
            or error __x"Bad return type {type}", type => $_[0];
    },
    lazy    => 1,
    coerce  => sub { return $_[0] || 'string' },
    builder => sub {
        my $self = shift;
        $self->_rset_code && $self->_rset_code->return_format;
    },
    trigger => sub { shift->clear_value_field },
);

has decimal_places => (
    is      => 'rw',
    isa     => Maybe[Int],
    lazy    => 1,
    builder => sub {
        my $self = shift;
        $self->_rset_code && $self->_rset_code->decimal_places;
    },
);

has '+value_field' => (
    default => sub {_format_to_field shift->return_type},
);

has '+string_storage' => (
    default => sub {shift->value_field eq 'value_text'},
);

has '+numeric' => (
    default => sub {
        my $self = shift;
        $self->return_type eq 'integer' || $self->return_type eq 'numeric';
    },
);

sub cleanup
{   my ($class, $schema, $id) = @_;
    $schema->resultset('Calc')->search({ layout_id => $id })->delete;
    $schema->resultset('Calcval')->search({ layout_id => $id })->delete;
}

# Returns whether an update is needed
sub write_code
{   my ($self, $layout_id, %options) = @_;
    my $rset = $self->_rset_code;
    my $need_update = !$rset->in_storage
        || $self->_rset_code->code ne $self->code
        || $self->_rset_code->return_format ne $self->return_type
        || $options{old_rset}->{multivalue} != $self->multivalue;
    # If changing return type, then remove all previous cached calc values, as
    # they will all be recalculated
    $self->schema->resultset($self->table_unique)->search({
        layout_id => $self->id,
    })->delete if $self->table_unique
        && $self->_rset_code->return_format && $self->_rset_code->return_format ne $self->return_type;
    $rset->layout_id($layout_id);
    $rset->code($self->code);
    $rset->return_format($self->return_type);
    $rset->decimal_places($self->decimal_places);
    $rset->insert_or_update;
    return $need_update;
}

sub resultset_for_values
{   my $self = shift;
    return $self->schema->resultset('CalcUnique')->search({
        layout_id => $self->id,
    },{
        group_by  => 'me.'.$self->value_field,
    }) if $self->value_field eq 'value_text';
}

sub validate_search
{   my ($self, $value) = @_;
    return $self->validate_daterange_search($value)
        if $self->return_type eq 'daterange';
    $self->validate($value);
}

sub validate
{   my ($self, $value) = @_;
    if ($self->return_type eq 'date')
    {
        return $self->parse_date($value);
    }
    elsif ($self->return_type eq 'daterange')
    {
        return $self->validate_daterange($value);
    }
    elsif ($self->return_type eq 'integer')
    {
        return 1 if $value eq '[CURUSER.ID]';
        return $value =~ /^-?[0-9]+$/;
    }
    elsif ($self->return_type eq 'numeric')
    {
        return looks_like_number($value);
    }
    return 1;
}

before import_hash => sub {
    my ($self, $values, %options) = @_;
    my $report = $options{report_only} && $self->id;
    notice __x"Update: code has been changed for field {name}", name => $self->name
        if $report && $self->code ne $values->{code};
    $self->code($values->{code});
    notice __x"Update: return_type from {old} to {new} for field {name}",
        old => $self->return_type, new => $values->{return_type}, name => $self->name
        if $report && $self->return_type ne $values->{return_type};
    $self->return_type($values->{return_type});
    notice __x"Update: decimal_places from {old} to {new} for field {name}",
        old => $self->decimal_places, new => $values->{decimal_places}, name => $self->name
        if $report && $self->return_type eq 'numeric' && (
            (defined $self->decimal_places xor defined $values->{decimal_places})
            || (defined $self->decimal_places && defined $values->{decimal_places} && $self->decimal_places != $values->{decimal_places})
        );
    $self->decimal_places($values->{decimal_places});
};

around export_hash => sub {
    my $orig = shift;
    my ($self, $values) = @_;
    my $hash = $orig->(@_);
    $hash->{code}           = $self->code;
    $hash->{return_type}    = $self->return_type;
    $hash->{decimal_places} = $self->decimal_places;
    return $hash;
};

# This list of regexes is copied directly from the plotly source code
my @regexes = qw/
    afghan
    \\b\\wland
    albania
    algeria
    ^(?=.*americ).*samoa
    andorra
    angola
    anguill?a
    antarctica
    antigua
    argentin
    armenia
    ^(?!.*bonaire).*\\baruba
    australia
    ^(?!.*hungary).*austria|\\baustri.*\\bemp
    azerbaijan
    bahamas
    bahrain
    bangladesh|^(?=.*east).*paki?stan
    barbados
    belarus|byelo
    ^(?!.*luxem).*belgium
    belize|^(?=.*british).*honduras
    benin|dahome
    bermuda
    bhutan
    bolivia
    ^(?=.*bonaire).*eustatius|^(?=.*carib).*netherlands|\\bbes.?islands
    herzegovina|bosnia
    botswana|bechuana
    bouvet
    brazil
    british.?indian.?ocean
    brunei
    bulgaria
    burkina|\\bfaso|upper.?volta
    burundi
    verde
    cambodia|kampuchea|khmer
    cameroon
    canada
    cayman
    \\bcentral.african.republic
    \\bchad
    \\bchile
    ^(?!.*\\bmac)(?!.*\\bhong)(?!.*\\btai)(?!.*\\brep).*china|^(?=.*peo)(?=.*rep).*china
    christmas
    \\bcocos|keeling
    colombia
    comoro
    ^(?!.*\\bdem)(?!.*\\bd[\\.]?r)(?!.*kinshasa)(?!.*zaire)(?!.*belg)(?!.*l.opoldville)(?!.*free).*\\bcongo
    \\bcook
    costa.?rica
    ivoire|ivory
    croatia
    \\bcuba
    ^(?!.*bonaire).*\\bcura(c|ç)ao
    cyprus
    czechoslovakia
    ^(?=.*rep).*czech|czechia|bohemia
    \\bdem.*congo|congo.*\\bdem|congo.*\\bd[\\.]?r|\\bd[\\.]?r.*congo|belgian.?congo|congo.?free.?state|kinshasa|zaire|l.opoldville|drc|droc|rdc
    denmark
    djibouti
    dominica(?!n)
    dominican.rep
    ecuador
    egypt
    el.?salvador
    guine.*eq|eq.*guine|^(?=.*span).*guinea
    eritrea
    estonia
    ethiopia|abyssinia
    falkland|malvinas
    faroe|faeroe
    fiji
    finland
    ^(?!.*\\bdep)(?!.*martinique).*france|french.?republic|\\bgaul
    ^(?=.*french).*guiana
    french.?polynesia|tahiti
    french.?southern
    gabon
    gambia
    ^(?!.*south).*georgia
    german.?democratic.?republic|democratic.?republic.*germany|east.germany
    ^(?!.*east).*germany|^(?=.*\\bfed.*\\brep).*german
    ghana|gold.?coast
    gibraltar
    greece|hellenic|hellas
    greenland
    grenada
    guadeloupe
    \\bguam
    guatemala
    guernsey
    ^(?!.*eq)(?!.*span)(?!.*bissau)(?!.*portu)(?!.*new).*guinea
    bissau|^(?=.*portu).*guinea
    guyana|british.?guiana
    haiti
    heard.*mcdonald
    holy.?see|vatican|papal.?st
    ^(?!.*brit).*honduras
    hong.?kong
    ^(?!.*austr).*hungary
    iceland
    india(?!.*ocea)
    indonesia
    \\biran|persia
    \\biraq|mesopotamia
    (^ireland)|(^republic.*ireland)
    ^(?=.*isle).*\\bman
    israel
    italy
    jamaica
    japan
    jersey
    jordan
    kazak
    kenya|british.?east.?africa|east.?africa.?prot
    kiribati
    ^(?=.*democrat|people|north|d.*p.*.r).*\\bkorea|dprk|korea.*(d.*p.*r)
    kuwait
    kyrgyz|kirghiz
    \\blaos?\\b
    latvia
    lebanon
    lesotho|basuto
    liberia
    libya
    liechtenstein
    lithuania
    ^(?!.*belg).*luxem
    maca(o|u)
    madagascar|malagasy
    malawi|nyasa
    malaysia
    maldive
    \\bmali\\b
    \\bmalta
    marshall
    martinique
    mauritania
    mauritius
    \\bmayotte
    \\bmexic
    fed.*micronesia|micronesia.*fed
    monaco
    mongolia
    ^(?!.*serbia).*montenegro
    montserrat
    morocco|\\bmaroc
    mozambique
    myanmar|burma
    namibia
    nauru
    nepal
    ^(?!.*\\bant)(?!.*\\bcarib).*netherlands
    ^(?=.*\\bant).*(nether|dutch)
    new.?caledonia
    new.?zealand
    nicaragua
    \\bniger(?!ia)
    nigeria
    niue
    norfolk
    mariana
    norway
    \\boman|trucial
    ^(?!.*east).*paki?stan
    palau
    palestin|\\bgaza|west.?bank
    panama
    papua|new.?guinea
    paraguay
    peru
    philippines
    pitcairn
    poland
    portugal
    puerto.?rico
    qatar
    ^(?!.*d.*p.*r)(?!.*democrat)(?!.*people)(?!.*north).*\\bkorea(?!.*d.*p.*r)
    moldov|b(a|e)ssarabia
    r(e|é)union
    r(o|u|ou)mania
    \\brussia|soviet.?union|u\\.?s\\.?s\\.?r|socialist.?republics
    rwanda
    barth(e|é)lemy
    helena
    kitts|\\bnevis
    \\blucia
    ^(?=.*collectivity).*martin|^(?=.*france).*martin(?!ique)|^(?=.*french).*martin(?!ique)
    miquelon
    vincent
    ^(?!.*amer).*samoa
    san.?marino
    \\bs(a|ã)o.?tom(e|é)
    \\bsa\\w*.?arabia
    senegal
    ^(?!.*monte).*serbia
    seychell
    sierra
    singapore
    ^(?!.*martin)(?!.*saba).*maarten
    ^(?!.*cze).*slovak
    slovenia
    solomon
    somali
    south.africa|s\\\\..?africa
    south.?georgia|sandwich
    \\bs\\w*.?sudan
    spain
    sri.?lanka|ceylon
    ^(?!.*\\bs(?!u)).*sudan
    surinam|dutch.?guiana
    svalbard
    swaziland
    sweden
    switz|swiss
    syria
    taiwan|taipei|formosa|^(?!.*peo)(?=.*rep).*china
    tajik
    thailand|\\bsiam
    macedonia|fyrom
    ^(?=.*leste).*timor|^(?=.*east).*timor
    togo
    tokelau
    tonga
    trinidad|tobago
    tunisia
    turkey
    turkmen
    turks
    tuvalu
    uganda
    ukrain
    emirates|^u\\.?a\\.?e\\.?$|united.?arab.?em
    united.?kingdom|britain|^u\\.?k\\.?$
    tanzania
    united.?states\\b(?!.*islands)|\\bu\\.?s\\.?a\\.?\\b|^\\s*u\\.?s\\.?\\b(?!.*islands)
    minor.?outlying.?is
    uruguay
    uzbek
    vanuatu|new.?hebrides
    venezuela
    ^(?!.*republic).*viet.?nam|^(?=.*socialist).*viet.?nam
    ^(?=.*\\bu\\.?\\s?k).*virgin|^(?=.*brit).*virgin|^(?=.*kingdom).*virgin
    ^(?=.*\\bu\\.?\\s?s).*virgin|^(?=.*states).*virgin
    futuna|wallis
    western.sahara
    ^(?!.*arab)(?!.*north)(?!.*sana)(?!.*peo)(?!.*dem)(?!.*south)(?!.*aden)(?!.*\\bp\\.?d\\.?r).*yemen
    ^(?=.*peo).*yemen|^(?!.*rep)(?=.*dem).*yemen|^(?=.*south).*yemen|^(?=.*aden).*yemen|^(?=.*\\bp\\.?d\\.?r).*yemen
    yugoslavia
    zambia|northern.?rhodesia
    zanzibar
    zimbabwe|^(?!.*northern).*rhodesia'
/;

sub check_country
{   my ($self, $country) = @_;
    foreach (@regexes)
    {
        return 1 if $country =~ qr/$_/i;
    }
    return 0;
}

1;
