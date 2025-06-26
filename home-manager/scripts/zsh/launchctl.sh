function launchctl_restart {
  launchctl stop $1
  launchctl start $1
  return 0
}
