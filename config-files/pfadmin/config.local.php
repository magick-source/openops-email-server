<?php
/**
 * DO NOT CHANGE MANUALLY!
 */

$CONF['configured'] = true;

$CONF['setup_password'] = '$PFADMIN_SETUP_CHECK';

$CONF['database_type'] = 'mysqli';
$CONF['database_host'] = '127.0.0.1';
$CONF['database_user'] = 'postfixadmin';
$CONF['database_password'] = '$DB_POSTFIXADMIN_PASSWORD';
$CONF['database_name'] = '$DB_POSTFIX';
$CONF['database_prefix'] = '';

$CONF['admin_email'] = '$POSTMASTER_EMAIL';

$CONF['default_aliases'] = array(
  'abuse'       => 'abuse@$MX_MAIN_DOMAIN',
  'hostmaster'  => 'hostmaster@$MX_MAIN_DOMAIN',
  'postmaster'  => 'postmaster@$MX_MAIN_DOMAIN',
  'webmaster'   => 'webmaster@$MX_MAIN_DOMAIN',
);

$CONF['show_footer_text'] = 'NO';
