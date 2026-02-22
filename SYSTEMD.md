# Setup with systemd

## Prerequisites

- Ruby and Rails installed
- Project cloned to `/var/www/tiny_pixel`
- User `deploy` with appropriate permissions

## Create systemd Service Files

### Web Server Service

Create `/etc/systemd/system/tiny_pixel-web.service`:

```
[Unit]
Description=Your App Rails Web Server
After=network.target

[Service]
Type=simple
User=deploy
WorkingDirectory=/var/www/tiny_pixel
Environment=RAILS_ENV=production
ExecStart=/usr/local/bin/bundle exec rails server -b 0.0.0.0 -p 3000
Restart=always

[Install]
WantedBy=multi-user.target
```

### Solid Queue Service
Create `/etc/systemd/system/tiny_pixel-solidqueue.service`:

```
[Unit]
Description=Your App Solid Queue Worker
After=network.target

[Service]
Type=simple
User=deploy
WorkingDirectory=/var/www/tiny_pixel
Environment=RAILS_ENV=production
ExecStart=/usr/local/bin/bundle exec rake solid_queue:start
Restart=always

[Install]
WantedBy=multi-user.target
```

## Enable and Start Services

```bash
sudo systemctl daemon-reload
sudo systemctl enable tiny_pixel-web
sudo systemctl enable tiny_pixel-solidqueue
sudo systemctl start tiny_pixel-web
sudo systemctl start tiny_pixel-solidqueue
```

## Check Status

```bash
sudo systemctl status tiny_pixel-web
sudo systemctl status tiny_pixel-solidqueue
```

## View Logs

```bash
sudo journalctl -u tiny_pixel-web -f
sudo journalctl -u tiny_pixel-solidqueue -f
```
