# CLI-Shortcuts
Is a simple DSL that provides shortcuts on the command line. The basic syntax is 
`s shortCutToUse options command`

### Shortcuts
#### For
The for shortcut creates a for loop (for i in $variable)   
```
$ s for 'george bob bill' echo hello {}
hello george
hello bob
hello bill
```

#### Loop
The loop shortcut creates a loop that will loop X times or loop through a range
```
$ s loop 5 echo count {} 
count 1
count 2
count 3
count 4
count 5
```

Or using a range
```
$ s loop 2 4 echo count {} 
count 2
count 3
count 4
```

#### Loopf
The loopf loops through a file
```
$ cat pinglist  
google.com
yahoo.com
$ s loopf pinglist ping -c1 {}
PING google.com (172.217.6.14) 56(84) bytes of data.
. . .
. . .
PING yahoo.com (98.139.183.24) 56(84) bytes of data.
. . .
. . .
```
