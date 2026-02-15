{...}: {
  # DigitalOcean Provider
  terraform.required_providers.digitalocean = {
    source = "digitalocean/digitalocean";
    version = "~> 2.75";
  };

  # API Token (環境変数 DIGITALOCEAN_TOKEN から取得)
  provider.digitalocean = {};

  # SSH Key (既存のキーを参照)
  data.digitalocean_ssh_key.default = {
    name = "default";
  };

  # NixOS カスタムイメージ
  resource.digitalocean_custom_image.nixos = {
    name = "nixos-minecraft";
    url = "https://github.com/akazdayo/minecraft-server-nix/releases/download/latest/nixos-digitalocean-do.qcow2.gz";
    regions = ["sgp1"];
  };

  # Droplet
  resource.digitalocean_droplet.minecraft = {
    image = "\${digitalocean_custom_image.nixos.id}";
    name = "minecraft-server";
    region = "sgp1";
    size = "s-1vcpu-1gb";
    ssh_keys = ["\${data.digitalocean_ssh_key.default.id}"];
  };

  # Outputs
  output.droplet_ip = {
    value = "\${digitalocean_droplet.minecraft.ipv4_address}";
    description = "The public IPv4 address of the Droplet";
  };
}
