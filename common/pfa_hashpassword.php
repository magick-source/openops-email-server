<?php

  if ( $argc < 2) {
    die("Password missing. usage php pfa_hashpassword.php <password>\n");
  }

  $password = $argv[1];
  $hash = password_hash( $password, PASSWORD_DEFAULT );

  echo $hash."\n";
?>
