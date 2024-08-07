# Linkspace configuration.  Also see the files in the "environments"
# directory that extend this configuration.
#
# Your application's name
appname: "Linkspace"

# The default layout to use for your application (located in
# views/layouts/main.tt)
layout: "main"

# when the charset is set to UTF-8 Dancer2 will handle for you
# all the magic of encoding and decoding. You should not care
# about unicode within your app when this setting is set (recommended).
charset: "UTF-8"

# template engine
# simple: default and very basic template engine
# template_toolkit: TT

template: "template_toolkit"

logger: LogReport

session: "YAML"

engines:
  session:
    YAML:
      session_dir: "/tmp/dancer-sessions"
      cookie_duration: 3600
      cookie_name: linkspace.session
      is_secure: 1 # Comment out or remove if using HTTP

gads:
  header: "HEADER"
  hostlocal: 1     # Whether to fetch files such as jquery.js locally
  dateformat: "yyyy-MM-dd" # In CLDR format. Not all options available for datetime picker
  email_from: '"Linkspace" <<%= $config->{"email"} %>>' # Emails are sent from this
  aup: 0 # Whether to show an acceptable use policy
  login_instance: 1 # The config values used for login page
  default_instance: 1 # The default instance on login, if more than one
  url: <%= $config->{"url"} %> # Used for URLs in overnight email alerts
  # legacy_menu: 0
  # aup_accept: I accept these terms # Use to change default accept button
  message_prefix: |
    This email has been generated and sent from Linkspace. Replies
    will be directed to the sender of the message.
  user_status: 0 # Whether to show user status on login
  user_status_message: |
    You must accept that you will treat this system with
    respect. And be gentle please.

plugins:
  LogReport:
    session_messages: [ NOTICE, MISTAKE, WARNING, ERROR, FAULT, ALERT, FAILURE, PANIC ]
  DBIC:
    default:
      dsn: dbi:Pg:database=<%= $config->{"db_name"} %>;host=<%= $config->{"db_host"} %>
      schema_class: GADS::Schema
      user: <%= $config->{"db_user"} %>
      password: <%= $config->{"db_pass"} %>
      options:
        RaiseError: 1
        PrintError: 1
        quote_names: 1
  Auth::Extensible:
    no_default_pages: 1
    no_login_handler: 1
    record_lastlogin: 1
    mailer:
      module: Mail::Message
      options:
        via: sendmail
        sendmail_options:
          - "-f"
          - <%= $config->{"email"} %>
    mail_from: '"Linkspace Database" <<%= $config->{"email"} %>>'
    password_reset_text: GADS::reset_text
    welcome_text: GADS::welcome_text
    realms:
      dbic:
        provider: DBIC
        user_as_object: 1
        users_resultset: User
        roles_resultset: Permission
        user_roles_resultset: UserPermission
        roles_role_column: name
        roles_key: permission
        password_expiry_days: 60
        users_pwchanged_column: pwchanged
        users_pwresetcode_column: resetpw
        encryption_algorithm: SHA-512
        user_valid_conditions:
          deleted: ~
          account_request: 0
