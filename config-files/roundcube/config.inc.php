<?php

/*
 +-----------------------------------------------------------------------+
 | Local configuration for the Roundcube Webmail installation.           |
 |                                                                       |
 | Generated automatically. DO NOT CHANGE MANUALLY!                      |
 |                                                                       |
 | see defaults.inc.php for confs and more info                          |
 +-----------------------------------------------------------------------+
*/

$config = array();

$config['db_dsnw'] = 'mysqli://roundcube:$DB_ROUNDCUBE_PASSWORD@localhost/$DB_ROUNDCUBE';
$config['default_host'] = 'tls://$MX_HOSTNAME';
$config['smtp_server'] = 'tls://$MX_HOSTNAME';

$config['product_name'] = 'Roundcube Webmail';

// this key is used to encrypt the users imap password which is stored
// in the session record (and the client cookie if remember password is enabled).
// please provide a string of exactly 24 chars.
// YOUR KEY MUST BE DIFFERENT THAN THE SAMPLE VALUE FOR SECURITY REASONS
$config['des_key'] = '$COOKIEKEY_ROUNDCUBE';

// List of active plugins (in plugins/ directory)
$config['plugins'] = array(
    'archive',
    'zipdownload',
);

// skin name: folder from skins/
$config['skin'] = 'larry';

$config['log_driver'] = 'syslog';

$config['temp_dir'] = '$MAIL_DIR/temp/roundcube';

