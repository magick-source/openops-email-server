<?php
/**
 * DO NOT CHANGE MANUALLY!
 */

$CONF['configured'] = true;

$CONF['setup_password'] = '1ad9399477af0eea910aca29400638d8:da9d08c2a76a1ace89e4e12364b312845123bc40';

$CONF['postfix_admin_url'] = '';
$CONF['postfix_admin_path'] = dirname(__FILE__);

$CONF['default_language'] = 'en';

$CONF['database_type'] = 'mysql';
$CONF['database_host'] = '127.0.0.1';
$CONF['database_user'] = 'postfixadmin';
$CONF['database_password'] = '$DB_POSTFIXADMIN_PASSWORD';
$CONF['database_name'] = '$DB_POSTFIX';
$CONF['database_prefix'] = '';

$CONF['database_prefix'] = '';
$CONF['database_tables'] = array (
    'admin' => 'admin',
    'alias' => 'alias',
    'alias_domain' => 'alias_domain',
    'config' => 'config',
    'domain' => 'domain',
    'domain_admins' => 'domain_admins',
    'fetchmail' => 'fetchmail',
    'log' => 'log',
    'mailbox' => 'mailbox',
    'vacation' => 'vacation',
    'vacation_notification' => 'vacation_notification',
    'quota' => 'quota',
    'quota2' => 'quota2',
);

$CONF['admin_email'] = '$POSTADMIN_EMAIL';

$CONF['smtp_server'] = 'localhost';
$CONF['smtp_port'] = '25';

$CONF['encrypt'] = 'md5crypt';

$CONF['min_password_length'] = 5;

$CONF['generate_password'] = 'NO';
$CONF['show_password'] = 'NO';

$CONF['page_size'] = '25';

$CONF['default_aliases'] = array (
);

$CONF['domain_path'] = 'YES';
$CONF['domain_in_mailbox'] = 'NO';
$CONF['maildir_name_hook'] = 'NO';

$CONF['aliases'] = '10';
$CONF['mailboxes'] = '10';
$CONF['maxquota'] = '10';

$CONF['quota'] = 'NO';
$CONF['quota_multiplier'] = '1024000';

$CONF['vacation_control_admin'] = 'YES';
$CONF['domain_quota'] = 'YES';

$CONF['transport'] = 'YES';
$CONF['transport_options'] = array (
  'dovecot',
  'virtual',
  'mlist',
  'relay'
);
$CONF['transport_default'] = 'dovecot';

$CONF['vacation'] = 'NO';

$CONF['alias_control'] = 'NO';
$CONF['alias_control_admin'] = 'NO';
$CONF['special_alias_control'] = 'NO';

$CONF['alias_goto_limit'] = '0';

$CONF['alias_domain'] = 'YES';

$CONF['backup'] = 'YES';
$CONF['sendmail'] = 'YES';
$CONF['logging'] = 'YES';
$CONF['fetchmail'] = 'YES';
$CONF['fetchmail_extra_options'] = 'NO';
$CONF['show_header_text'] = 'NO';
$CONF['header_text'] = ':: Postfix Admin ::';

$CONF['user_footer_link'] = "";
$CONF['show_footer_text'] = 'NO';
$CONF['footer_text'] = '';
$CONF['footer_link'] = '';

$CONF['welcome_text'] = <<<EOM
Hi,

Welcome to your new account.
EOM;

$CONF['emailcheck_resolve_domain']='YES';

$CONF['show_status']='NO';
$CONF['show_status_key']='NO';
$CONF['show_status_text']='&nbsp;&nbsp;';
$CONF['show_undeliverable']='NO';
$CONF['show_undeliverable_color']='tomato';
$CONF['show_undeliverable_exceptions']=array("unixmail.domain.ext","exchangeserver.domain.ext","gmail.com");
$CONF['show_popimap']='NO';
$CONF['show_popimap_color']='darkgrey';
$CONF['show_custom_domains']=array("subdomain.domain.ext","domain2.ext");
$CONF['show_custom_colors']=array("lightgreen","lightblue");
$CONF['recipient_delimiter'] = "";


$CONF['used_quotas'] = 'NO';
$CONF['new_quota_table'] = 'NO';

$CONF['theme_logo'] = 'images/logo-default.png';
$CONF['theme_css'] = 'css/default.css';

$CONF['xmlrpc_enabled'] = false;

