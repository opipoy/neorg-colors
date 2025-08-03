# neorg colors
### **NOTE** this is an expiramental branch some changes may preduce bugs
this is a module for neorg that allows for changing the text color
## syntax
for now the syntax of the module is pretty simple and is limited by lines (it can color only lines):
#### example:
```norg
ncolor:#ff0000 this text color is now red! nend_color
```

### changing the color inside the text
```
<your text>ncolor:<hex color> <some colored text> nend_color
```
#### example:
```
this is an example with ncolor:#ff0000 colored nend_color text
```

### changing the color on multible lines
```norg
ncolor:<hex color>
<your text on diffrent lines>
nend_color
```
#### example:
```
ncolor:#ffffff
this text is now white
and this one is also white
ncolor:#0000ff
this text is now blue
this one is also blue
nend_color
this is now regular text. it lookes normal
```

