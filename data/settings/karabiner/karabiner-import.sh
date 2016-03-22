#!/bin/sh

cli=/Applications/Karabiner.app/Contents/Library/bin/karabiner

$cli set option.ubiq_vimnormal_insert 1
/bin/echo -n .
$cli set repeat.initial_wait 333
/bin/echo -n .
$cli set remap.hjkl_arrow 1
/bin/echo -n .
$cli set parameter.mousekey_repeat_wait_of_pointer 10
/bin/echo -n .
$cli set repeat.wait 20
/bin/echo -n .
$cli set option.vimode_control_hjkl 1
/bin/echo -n .
$cli set parameter.mousekey_initial_wait_of_pointer 15
/bin/echo -n .
$cli set parameter.mousekey_high_speed_of_pointer 100
/bin/echo -n .
$cli set remap.mouse_keys_mode_2 1
/bin/echo -n .
$cli set parameter.maximum_speed_of_pointer 100
/bin/echo -n .
/bin/echo
