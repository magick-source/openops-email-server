require "fileinto";

if header :contains "X-Spam-Level" "**********" {
  discard;
  stop;
}

if header :contains "X-Spam-Flag" "YES" {
  fileinto "SPAM";
}

