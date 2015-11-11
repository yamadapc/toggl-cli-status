# toggl-cli-status
See your current Toggl Time Entry in the Terminal.

![demo](/demo.gif)

_Using it on tmux or zsh is super buggy/slow atm._

## Using it on zsh
On your theme:
```
RPROMPT="%{$fg_bold[grey]%}$(toggl-cli-status -s)"
```

How mine looks:
![](https://www.dropbox.com/s/cfmupaugip2ywze/Screenshot%202015-11-11%2020.27.16.png?dl=1)

## Using it on tmux
```
set -g status-right '#(toggl-cli-status -s)'
```

## License
This code is licensed under the MIT license. For more information please refer
to the [LICENSE](/LICENSE) file.
