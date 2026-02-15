# Minecraft Server on DigitalOcean with NixOS

Terranix + deploy-rs で NixOS Droplet をデプロイ

## 前提

- Nix (flakes有効)
- DigitalOcean アカウント
- SSH キー (という名前でDigitalOceanにアップロード済み)

## 準備

```bash
# 環境変数を設定
export DIGITALOCEAN_TOKEN="dop_v1_xxxxxxxxxxxxx"
```

## インフラ作成 (Terraform)

```bash
nix run .#tf-plan
nix run .#tf-apply
```

IPアドレスを確認:

```bash
tofu output droplet_ip
```

## NixOSデプロイ

`flake.nix` の `deploy.nodes.droplet.hostname` を実際のIPアドレスに書き換えて:

```bash
nix run github:serokell/deploy-rs -- .#droplet
```

## 構成

| ファイル | 説明 |
|---------|------|
| `terraform.nix` | Terranix設定 (Droplet作成) |
| `droplet-configuration.nix` | NixOS設定 |
| `flake.nix` | Flake (deploy-rs設定) |
| `do-image.nix` | DigitalOceanイメージビルド |

## 削除

```bash
nix run .#tf-destroy
```
