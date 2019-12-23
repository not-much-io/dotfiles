.PHONY: apply_bolt
apply_bolt:
	sudo cp bolt/configuration.nix /etc/nixos/configuration.nix

.PHONY: apply_workstation
apply_workstation:
	sudo cp workstation/configuration.nix /etc/nixos/configuration.nix
