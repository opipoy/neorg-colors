# 🎨 neorg colors

### 📝 **NOTE** this is an expiramental branch some changes may preduce bugs
this is a module for neorg that allows for changing the text color

## 💾 Installation
### Requirements
only a working Neorg installation
### adding the plugin to your setup
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


## 🧑‍💻 syntax
### ❗Notice: Syntax Change❗
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

### using highlights to color the text 
```norg
ncolor:hex color,highlight color
this text is highlighted & colored :)
nend_color
```
#### example
```norg
ncolor:#ffffff,#000000
this text is white with a black background
ncolor:#ff0000,#0000ff
this text is red with a blue background
nend_color
```

## ⚙️ Configre
### custom color names
you can add custom names to your choosing:
```lua
["external.neorg-colors"] = {
    config = {
        color_name = "<your color name>"
        end_name = "<your end color name>"
    }
}
```
#### ❗Notice❗:
some characters may conflict with neorgs syntax.
please check documentation to see if theres a conflict
