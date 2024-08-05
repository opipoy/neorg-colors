# neorg colors
this is a module for neorg that allows for changing the text color
## syntax
for now the syntax of the module is pretty simple and is limited by lines (it can color only lines):
### changing the color on current line
```
@color:<hex color> <your text>
```
#### example:
```
@color:#ff0000 this text color is now red!
```
### changing the color on multible lines
```
&color:<hex color>
<your text on diffrent lines>
&end_color
```
#### example:
```
&color:#ffffff
this text is now white
and this one is also white
&color:#0000ff
this text is now blue
this one is also blue
&end_color
this is now regular text. it lookes normal
```
