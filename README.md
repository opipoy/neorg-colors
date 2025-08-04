# 🎨 Neorg Colors

### 📝 **NOTE** this is an experimental branch, some changes may produce bugs
This is a module for neorg that allows you to change the text color

## 💾 Installation
### Requirements
Only a working Neorg installation
### Adding the plugin to your setup
<details>
    <summary>lazy.nvim</summary>

```lua
-- neorg.lua or where you placed your neorg installation in nvim
{
    "nvim-neorg/neorg",
    lazy = false,
    version = "*",
    config = true,
    dependencies = {
        -- all your other dependencies
        { "opipoy/neorg-colors" }
    }
}
```
</details>


## 🧑‍💻 Syntax
### ❗Notice: Syntax Change❗
#### Example
```norg
ncolor:#ff0000 this text color is now red! nend_color
```

### Changing the color inside the text
```
<your text>ncolor:<hex color> <some colored text> nend_color
```
#### Example
```
this is an example with ncolor:#ff0000 colored nend_color text
```

### Changing the color on multiple lines
```norg
ncolor:<hex color>
<your text on different lines>
nend_color
```
#### Example
```
ncolor:#ffffff
this text is now white
and this one is also white
ncolor:#0000ff
this text is now blue
this one is also blue
nend_color
this is now regular text. it looks normal
```

### Using highlights to color the text 
```norg
ncolor:hex color,highlight color
this text is highlighted & colored :)
nend_color
```
#### Example
```norg
ncolor:#ffffff,#000000
this text is white with a black background
ncolor:#ff0000,#0000ff
this text is red with a blue background
nend_color
```

## ⚙️ Configure
### Custom color names
You can add custom names to your choosing:
```lua
["external.neorg-colors"] = {
    config = {
        color_name = "<your color name>"
        end_name = "<your end color name>"
    }
}
```
#### ❗Notice❗
Some characters may conflict with Neorg's syntax.
Please check the documentation to see if there's a conflict
