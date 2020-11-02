<?php
  $hostname = $_SERVER['HTTP_HOST'];
  header("Location: https://$hostname/", TRUE, 301);

?>
