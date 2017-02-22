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


```
$ ls test/*.txt 
test/test2.txt  test/test3.txt  test/test.txt

$ s for "`ls test/*.txt`" echo {basename}
test2
test3
test

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
### Special variables
There are a few variables that can be accessed when executing commands    

**{}** - The current iterable    
**{basename}** - If the iterable is a filename this will contain the basename of that filename    
**{ext}** - If the iterable is a filename this will contain the extension of that filename    
**{dirname}** - If the iterable is a filename this will contain the path of that filename (if provided in the iterable)

### Special Syntax
There is special syntax that can make life easier    
**@@** - End the current command. This is the equivalent of ; (e.g. `echo -n hi, @@ echo how are you `). @@ can be escaped like so \@\@ or even just @\@     
**{err}** - Prints the error code of the last command on the current line (echo -n $?)    
**{errnl}** - Prints the error code of the last command on the current line (echo $?)    