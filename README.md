# camera_rec

`rpicam-vid` を使って Raspberry Pi で連続録画（1時間ごと分割）するための構成です。

## クイックスタート（2台目向け）

1. Raspberry Pi にこのリポジトリをクローンする
2. 必要ならカメラアプリをインストールする
   - `sudo apt update && sudo apt install -y rpicam-apps`
3. インストーラを実行し、機器ごとの値（ユーザー名、保存先、解像度など）を入力する
   - `sudo bash ./script/install-systemd.sh`
4. サービス状態を確認する
   - `sudo systemctl status rpicam-record.service --no-pager`

## 一般的な入力値例（GitHub公開向け）

環境依存する値はプレースホルダで記載しています。

```text
Service user: <service_user>
Recording root: /mnt/recordings
Width: 1280
Height: 720
Framerate: 15
Codec: h264
Output extension: h264
Disable preview (1/0): 1
Boundary guard seconds: 5
```

## 初回セットアップの入力例

`sudo bash ./script/install-systemd.sh` 実行時の入力例です（`[]` は Enter で既定値を使う項目です）。

```text
Service user [pi]: <service_user>
Recording root [/mnt/recordings]: /mnt/recordings
Width [1280]: 1280
Height [720]: 720
Framerate [15]: 15
Codec [h264]: h264
Output extension [h264]: h264
Disable preview (1/0) [1]: 1
Boundary guard seconds [5]: 5
```

例: 高画質にしたい場合は `Width` / `Height` / `Framerate` を `1920` / `1080` / `30` に変更します。

## 保存先を別サーバーにする場合（マウント手順）

以下は Raspberry Pi 側での一般的な手順です。  
マウント先は例として `/mnt/recordings` を使います。

### SMB/CIFS の例

1. パッケージを入れる
   - `sudo apt update && sudo apt install -y cifs-utils`
2. マウントポイント作成
   - `sudo mkdir -p /mnt/recordings`
3. 認証情報ファイル作成
   - `sudo mkdir -p /etc/samba`
   - `sudo nano /etc/samba/recordings.cred`
4. 認証情報を記入
   - `username=<smb_user>`
   - `password=<smb_password>`
   - `domain=<domain_or_workgroup>`（不要なら省略）
5. 権限を絞る
   - `sudo chmod 600 /etc/samba/recordings.cred`
6. `/etc/fstab` に追記
   - `//<server_host>/<share_name> /mnt/recordings cifs credentials=/etc/samba/recordings.cred,iocharset=utf8,uid=1000,gid=1000,file_mode=0664,dir_mode=0775,nofail,_netdev,x-systemd.automount 0 0`
7. 反映と確認
   - `sudo mount -a`
   - `mount | grep /mnt/recordings`

### NFS の例

1. パッケージを入れる
   - `sudo apt update && sudo apt install -y nfs-common`
2. マウントポイント作成
   - `sudo mkdir -p /mnt/recordings`
3. `/etc/fstab` に追記
   - `<server_host>:/<export_path> /mnt/recordings nfs defaults,nofail,_netdev,x-systemd.automount 0 0`
4. 反映と確認
   - `sudo mount -a`
   - `mount | grep /mnt/recordings`

### 運用時の注意

1. `uid` / `gid` はサービス実行ユーザーに合わせてください（`id <service_user>` で確認）。
2. 録画サービス起動前に、必ずマウントできていることを確認してください。
3. インストーラ実行時の `Recording root` はマウントポイント（例: `/mnt/recordings`）を指定してください。

## インストーラが実行する内容

- 録画スクリプトを `/usr/local/bin/rpicam-record.sh` に配置
- systemd サービスを `/etc/systemd/system/rpicam-record.service` に配置
- 実行時設定を `/etc/default/rpicam-record` に出力
- `rpicam-record.service` を有効化して起動

## 手動セットアップ（任意）

対話式インストールを使わない場合:

1. `config/rpicam-record.env.example` を `/etc/default/rpicam-record` にコピーして値を編集
2. `service/rpicam-record.service` 内の `__RUN_AS_USER__` を実行ユーザー名に置換
3. ファイルを配置
   - `sudo install -m 755 script/rpicam-record.sh /usr/local/bin/rpicam-record.sh`
   - `sudo install -m 644 service/rpicam-record.service /etc/systemd/system/rpicam-record.service`
4. 読み込み直しと起動
   - `sudo systemctl daemon-reload`
   - `sudo systemctl enable --now rpicam-record.service`

## 補足

- サービス実行ユーザーが `video` グループにいない場合は追加してください
  - `sudo usermod -aG video <user>`
- 既定の保存先は `/mnt/recordings` です
