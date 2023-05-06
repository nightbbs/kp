#!/usr/bin/perl
open(resume_file, '<', "$ENV{'HOME'}/.config/kp/kp.resume") or die $!;
$need_num = 1;
while(<resume_file>) {
    $buffer =`emacsclient --no-wait  -e "(eshell)"`;
    $buffer =~ s/#\<buffer\ (.*)>/$1/;
    $ec1 = "emacsclient --no-wait  -e \"\(with-current-buffer \\\"$buffer\\\" \(insert \\\"k -r $need_num\\\"\)\)\"";
    $ec2 = "emacsclient --no-wait  -e \"\(with-current-buffer \\\"$buffer\\\" \(eshell-send-input\)\)\"";
    system("$ec1");
    system("$ec2");
    sleep 2;
    $need_num++;
}
`emacsclient --no-wait  -e "(eshell)"`;
`emacsclient --no-wait  -e "(eshell)"`;
    
