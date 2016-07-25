
# start cloudbase-init service and set to auto-start
start-process -nonewwindow -FilePath "C:/Windows/system32/sc.exe" -ArgumentList "config cloudbase-init start= auto" -wait
start-process -nonewwindow -FilePath "C:/Windows/system32/sc.exe" -ArgumentList "start cloudbase-init" -wait

exit 0
