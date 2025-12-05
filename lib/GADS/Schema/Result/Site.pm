use utf8;
package GADS::Schema::Result::Site;

use strict;
use warnings;

use base 'DBIx::Class::Core';

use Lingua::EN::Inflect qw/PL/;

use JSON qw(decode_json encode_json);
use File::Temp qw/tempfile/;
use GADS::Config;

__PACKAGE__->load_components("InflateColumn::DateTime");

__PACKAGE__->table("site");

__PACKAGE__->add_columns(
  "id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "host",
  { data_type => "varchar", is_nullable => 1, size => 128 },
  "name",
  { data_type => "text", is_nullable => 1 },
  "created",
  {
    data_type => "datetime",
    datetime_undef_if_invalid => 1,
    is_nullable => 1,
  },
  "email_welcome_text",
  { data_type => "text", is_nullable => 1 },
  "email_welcome_subject",
  { data_type => "text", is_nullable => 1 },
  "email_delete_text",
  { data_type => "text", is_nullable => 1 },
  "email_delete_subject",
  { data_type => "text", is_nullable => 1 },
  "email_reject_text",
  { data_type => "text", is_nullable => 1 },
  "email_reject_subject",
  { data_type => "text", is_nullable => 1 },
  "register_text",
  { data_type => "text", is_nullable => 1 },
  "homepage_text",
  { data_type => "text", is_nullable => 1 },
  "homepage_text2",
  { data_type => "text", is_nullable => 1 },
  "register_title_help",
  { data_type => "text", is_nullable => 1 },
  "register_freetext1_help",
  { data_type => "text", is_nullable => 1 },
  "register_freetext2_help",
  { data_type => "text", is_nullable => 1 },
  "register_email_help",
  { data_type => "text", is_nullable => 1 },
  "register_organisation_help",
  { data_type => "text", is_nullable => 1 },
  "register_organisation_name",
  { data_type => "text", is_nullable => 1 },
  "register_organisation_mandatory",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "register_department_help",
  { data_type => "text", is_nullable => 1 },
  "register_department_name",
  { data_type => "text", is_nullable => 1 },
  "register_department_mandatory",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "register_team_help",
  { data_type => "text", is_nullable => 1 },
  "register_team_name",
  { data_type => "text", is_nullable => 1 },
  "register_team_mandatory",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "register_notes_help",
  { data_type => "text", is_nullable => 1 },
  "register_freetext1_name",
  { data_type => "text", is_nullable => 1 },
  "register_freetext2_name",
  { data_type => "text", is_nullable => 1 },
  "register_show_organisation",
  { data_type => "smallint", default_value => 1, is_nullable => 0 },
  "register_show_department",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "register_show_team",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "register_show_title",
  { data_type => "smallint", default_value => 1, is_nullable => 0 },
  "register_show_provider",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "hide_account_request",
  { data_type => "smallint", default_value => 0, is_nullable => 0 },
  "remember_user_location",
  { data_type => "smallint", default_value => 1, is_nullable => 0 },
  "user_editable_fields",
  { data_type => "text", is_nullable => 1 },
  "register_freetext1_placeholder",
  { data_type => "text", is_nullable => 1 },
  "register_freetext2_placeholder",
  { data_type => "text", is_nullable => 1 },
  "account_request_notes_name",
  { data_type => "text", is_nullable => 1 },
  "account_request_notes_placeholder",
  { data_type => "text", is_nullable => 1 },
  "security_marking",
  { data_type => "text", is_nullable => 1 },
  "site_logo",
  { data_type => "longblob", is_nullable => 1 },
);

__PACKAGE__->set_primary_key("id");

__PACKAGE__->has_many(
  "audits",
  "GADS::Schema::Result::Audit",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "groups",
  "GADS::Schema::Result::Group",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "imports",
  "GADS::Schema::Result::Import",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "instances",
  "GADS::Schema::Result::Instance",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "organisations",
  "GADS::Schema::Result::Organisation",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "departments",
  "GADS::Schema::Result::Department",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "teams",
  "GADS::Schema::Result::Team",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "titles",
  "GADS::Schema::Result::Title",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "users",
  "GADS::Schema::Result::User",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "dashboards",
  "GADS::Schema::Result::Dashboard",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

__PACKAGE__->has_many(
  "providers",
  "GADS::Schema::Result::Authentication",
  { "foreign.site_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);

sub has_main_homepage
{   my $self = shift;
    return 1 if $self->homepage_text && $self->homepage_text !~ /^\s*$/;
    return 1 if $self->homepage_text2 && $self->homepage_text2 !~ /^\s*$/;
    return 0;
}

sub has_table_homepage
{   my $self = shift;
    foreach my $table ($self->instances)
    {
        return 1 if $table->homepage_text && $table->homepage_text !~ /^\s*$/;
        return 1 if $table->homepage_text2 && $table->homepage_text2 !~ /^\s*$/;
    }
    return 0;
}

sub organisation_name
{   my $self = shift;
    $self->register_organisation_name || 'Organisation';
}

sub organisation_name_plural
{   PL shift->organisation_name;
}

sub department_name
{   my $self = shift;
    $self->register_department_name || 'Department';
}

sub department_name_plural
{   PL shift->department_name;
}

sub team_name
{   my $self = shift;
    $self->register_team_name || 'Team';
}

sub team_name_plural
{   PL shift->team_name;
}

sub update_user_editable_fields
{   my ($self, @fieldnames) = @_;

    my %editable = map { $_ => 1 } @fieldnames;

    my @fields = $self->user_fields;

    $_->{editable} = $editable{$_->{name}} || 0
        foreach @fields;

    my $json = encode_json +{
        map { $_->{name} => $_->{editable} } @fields
    };

    $self->update({
        user_editable_fields => $json,
    });
}

sub user_fields_as_string
{   my $self = shift;
    join ', ', map $_->{description}, $self->user_fields;
}

sub user_field_is_editable {
  my $self = shift;
  my $field = shift;

  !!grep { $_->{name} eq $field && $_->{editable} } $self->user_fields();
}

sub user_field_by_description
{   my ($self, $description) = @_;
    $description or return;
    my ($field) = grep $description eq $_->{description}, $self->user_fields;
    $field;
}

sub provider_fields
{   my $self = shift;

    my @fields = (
        {
            name        => 'name',
            description => 'Provider Name',
            type        => 'freetext',
            placeholder => 'Provider Name',
            is_required => 1,
        },
        {
            name        => 'type',
            description => 'Type',
            type        => 'radio',
            is_required => 1,
        },
        {
          name          => 'enabled',
          description   => 'Enabled',
          type          => 'radio',
          placeholder   => '',
        },
        {
          name          => 'sso_xml',
          description   => 'Entity ID',
          type          => 'freetext',
          placeholder   => 'Entity ID',
        },
        {
          name          => 'sso_url',
          description   => 'Reply URL / SSO URL / ACS URL',
          type          => 'freetext',
          placeholder   => '',
        },
        {
          name          => 'saml2_firstname',
          description   => 'User attribute for first name (optional)',
          type          => 'freetext',
          placeholder   => 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/givenname',
        },
        {
          name          => 'saml2_surname',
          description   => 'User attribute for surname (optional)',
          type          => 'freetext',
          placeholder   => 'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/surname',
        },
        {
          name          => 'saml2_groupname',
          description   => 'Attribute for groupname (optional)',
          type          => 'freetext',
          placeholder   => 'http://schemas.xmlsoap.org/claims/Group',
        },
        {
          name        => 'saml2_nameid',
          description => 'SAML NameID format',
          type        => 'dropdown',
          is_required => 1,
        },
        {
          name          => 'xml',
          description   => 'Identity Provider Metadata XML',
          type          => 'file',
          placeholder   => '',
        },
        {
          name          => 'cacert',
          description   => 'Identity provider Signing/Encryption Certificate',
          type          => 'file',
          placeholder   => '',
        },
        {
          name          => 'sp_key',
          description   => 'LinkSpace Encryption/Signing Key',
          type          => 'file',
          placeholder   => '',
        },
        {
          name          => 'sp_cert',
          description   => 'LinkSpace Encryption/Signing Certificate',
          type          => 'file',
          placeholder   => '',
        },
        {
          name          => 'saml2_relaystate',
          description   => 'RelayState',
          type          => 'freetext',
          placeholder   => '',
        },
    );

    my $user_editable = decode_json($self->user_editable_fields || '{}');

    $_->{editable} = $user_editable->{$_->{name}} // 1 # Default to editable
        foreach @fields;

    return @fields;
}

sub user_fields
{   my $self = shift;

    my @fields = (
        {
            name        => 'firstname',
            description => 'Forename',
            type        => 'freetext',
            placeholder => 'Forename',
        },
        {
            name        => 'surname',
            description => 'Surname',
            type        => 'freetext',
            placeholder => 'Surname',
        },
        {
            name        => 'email',
            description => 'Email address',
            type        => 'freetext',
            placeholder => 'name@example.com',
            is_required => 1,
        },
        {
          name          => 'account_request_notes',
          description   => $self->account_request_notes_name || 'Notes',
          type          => 'textarea',
          placeholder   => $self->account_request_notes_placeholder || 'Notes',
          user_hidden => 1,
        }
    );
    push @fields, {
        name        => 'title',
        description => 'Title',
        type        => 'dropdown',
        placeholder => 'Select title',
        table       => 'title',
        field       => 'name',
    } if $self->register_show_title;
    push @fields, {
        name        => 'organisation',
        description => $self->organisation_name,
        type        => 'dropdown',
        placeholder => 'Select ' . $self->organisation_name,
        table       => 'organisation',
        field       => 'name',
    } if $self->register_show_organisation;
    push @fields, {
        name        => 'provider',
        description => 'Authentication Provider',
        type        => 'dropdown',
        placeholder => 'Select provider',
    } if $self->register_show_provider;
    push @fields, {
        name        => 'department_id',
        description => $self->department_name,
        type        => 'dropdown',
        placeholder => 'Select ' . $self->department_name,
        table       => 'department',
        field       => 'name',
    } if $self->register_show_department;
    push @fields, {
        name        => 'team_id',
        description => $self->team_name,
        type        => 'dropdown',
        placeholder => 'Select ' . $self->team_name,
        table       => 'team',
        field       => 'name',
    } if $self->register_show_team;
    push @fields, {
        name        => 'freetext1',
        description => $self->register_freetext1_name,
        type        => 'freetext',
        placeholder => $self->register_freetext1_placeholder || $self->register_freetext1_name,
    } if $self->register_freetext1_name;
    push @fields, {
        name        => 'freetext2',
        description => $self->register_freetext2_name,
        type        => 'freetext',
        placeholder => $self->register_freetext2_placeholder || $self->register_freetext2_name,
    } if $self->register_freetext2_name;
    
    my $user_editable = decode_json($self->user_editable_fields || '{}');

    $_->{editable} = $user_editable->{$_->{name}} // 1 # Default to editable
        foreach @fields;

    return @fields;
}

sub load_logo {
  my $self = shift;
  my $filecheck = GADS::Filecheck->instance();

  my $logo_path = $self->create_temp_logo or return;

  return +{
      'content_type' => $filecheck->get_filetype($logo_path),
      'filename'     => 'logo',
      'data'         => $self->site_logo
  };
}

sub create_temp_logo {
  my $self = shift;
  my $logo = $self->site_logo;

  return undef unless $logo;

  my ( $fh, $filename ) = tempfile(UNLINK => 1);
  print $fh $logo;
  close $fh;

  return $filename;
}

sub read_security_marking {
  my $self = shift;
  my $config = GADS::Config->instance;
  return $self->security_marking || $config->gads->{header};
}

1;
