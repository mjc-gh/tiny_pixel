### Setup

```
kamal server bootstrap
kamal registry login --skip-local
```

### Deploy

```
kamal deploy --skip-push --version sha-$(git rev-parse --short HEAD)
```
