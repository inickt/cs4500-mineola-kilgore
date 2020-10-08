# Mineola

This repository contains the work of Nick Thompson and Jake Hansen for Prof. Matthias Felleisen's section of CS4500 Software Development in the Fall 2020 term.

## TAHBPL Assignments
<details>
<summary>B – Command Line</summary>

## B
`xyes` will continuously print out the value of args as written, or `hello world` if no args are provided, ignoring whitespaces and joining all values in args with a single space.

### Usage
```
./xyes [OPTIONS] [optional args]
```

##### OPTIONS
`-limit` is the only supported flag for this program, and limits the output to 20 lines.

### File strucutre
```
B/
├─ xyes
└─ Other/
   └─ xyes.rkt
```

##### xyes
The executable file for this assignment

#### Other
Contains auxiliary files for this assignment

##### xyes.rkt
The source code for xyes

### Tests
Tests can be run using the command `raco test B/` when you are in the root of the repository.

</details>

<details>
<summary>C – JSON</summary>
TODO
</details>

<details>
<summary>D – GUI</summary>
TODO
</details>

<details>
<summary>E – TCP</summary>
TODO
</details>

## Projects

### Fish

*see [Fish/README.md](./Fish/README.md) for now*
<!---
These characters are useful for creating filestructure diagrams:
```
├
└
─
│
```
---!>
