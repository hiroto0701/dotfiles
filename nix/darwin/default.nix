{ self, username, ... }:
{
  imports = [ ./defaults.nix ./homebrew.nix ];

  nixpkgs.hostPlatform = "aarch64-darwin";

  # system.defaults と homebrew はこのユーザーとして実行される
  system.primaryUser = username;

  # Determinate Nix が Nix 本体 (/etc/nix/nix.conf、daemon) を管理するため nix-darwin 側は手放す
  nix.enable = false;

  system.stateVersion = 7;
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # defaults write 後にログアウト無しで反映される項目を増やす。
  # activation script は set -e で動くため、失敗しても activation を止めないようにする
  system.activationScripts.postActivation.text = ''
    launchctl asuser "$(id -u -- ${username})" sudo --user=${username} -- \
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u \
      || echo >&2 "warning: activateSettings -u failed (ignored)"
  '';
}
