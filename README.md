# MoouseOT Client

Client do MoouseOT baseado no OTClient Redemption.

---

## Estrutura do Projeto

```
MoouseOT_Client/
├── init.lua              # Configuração principal do client
├── otclientrc.lua        # Script de inicialização
├── manifest.json         # Checksums dos arquivos (usado pelo auto-updater)
├── modules/              # Módulos Lua do client (interface, console, updater, etc.)
├── mods/                 # Mods adicionais
├── data/                 # Fontes, imagens, sons, estilos, etc.
├── generate_manifest.ps1 # Script para gerar o manifest.json (NÃO vai pro Git)
└── .gitignore            # Arquivos ignorados pelo Git
```

---

## Como Funciona o Auto-Updater

1. O jogador baixa o ZIP do [Release](https://github.com/andre78451200-cloud/MoouseOT_Client/releases) e extrai
2. Ao abrir o client, o **updater** busca o `manifest.json` no GitHub
3. Compara os checksums (CRC32) dos arquivos locais com o manifest
4. Se algo mudou, baixa **apenas os arquivos diferentes**
5. Reinicia o client com os arquivos atualizados

---

## Como Fazer uma Atualização

### Passo 1: Editar os arquivos

Faça as alterações nos arquivos que precisar (Lua, OTUI, imagens, etc.)

### Passo 2: Regenerar o manifest

O manifest.json contém os checksums de todos os arquivos. **Sempre** que mudar qualquer arquivo, precisa regenerar:

```powershell
powershell -NoProfile -Command "& '.\generate_manifest.ps1' -GitHubUser 'andre78451200-cloud' -GitHubRepo 'MoouseOT_Client' -Branch 'main'"
```

### Passo 3: Commit e Push

```powershell
# Adicionar os arquivos alterados + o manifest
git add modules/pasta/arquivo_alterado.lua manifest.json

# Ou adicionar tudo de uma vez
git add -A

# Fazer o commit com uma mensagem descritiva
git commit -m "Descrição da alteração"

# Enviar para o GitHub
git push
```

### Exemplo Completo

Digamos que você corrigiu um bug no `console.lua`:

```powershell
# 1. Editar o arquivo (via VS Code ou outro editor)

# 2. Regenerar o manifest
powershell -NoProfile -Command "& '.\generate_manifest.ps1' -GitHubUser 'andre78451200-cloud' -GitHubRepo 'MoouseOT_Client' -Branch 'main'"

# 3. Commit + Push
git add modules/game_console/console.lua manifest.json
git commit -m "Fix bug no console do NPC"
git push
```

Pronto! Quando os jogadores reabrirem o client, o updater vai baixar automaticamente só o `console.lua` atualizado.

---

## Como Criar um Novo Release (ZIP)

Quando fizer mudanças grandes ou quiser atualizar o ZIP de download:

```powershell
# 1. Na pasta MoouseOT_Client, regenerar o manifest primeiro
powershell -NoProfile -Command "& '.\generate_manifest.ps1' -GitHubUser 'andre78451200-cloud' -GitHubRepo 'MoouseOT_Client' -Branch 'main'"

# 2. Commit e push
git add -A
git commit -m "Atualização v1.x"
git push

# 3. Voltar para a pasta pai (distribuicao) e criar o ZIP
cd ..
Compress-Archive -Path "MoouseOT_Client" -DestinationPath "MoouseOT_Client.zip" -Force

# 4. Deletar o release antigo e criar um novo
cd MoouseOT_Client
gh release delete v1.0.2 --yes --cleanup-tag
gh release create v1.0.3 "..\MoouseOT_Client.zip" --title "MoouseOT Client v1.0.3" --notes "MoouseOT Client - Download e extraia para jogar."
```

O link de download será:
```
https://github.com/andre78451200-cloud/MoouseOT_Client/releases/download/v1.0.3/MoouseOT_Client.zip
```

> **Importante:** Atualize o link no site se a versão mudar.

---

## Arquivos Ignorados pelo Git (.gitignore)

Estes arquivos **NÃO** vão para o repositório:

| Arquivo/Pasta | Motivo |
|---|---|
| `*.exe`, `*.dll` | Binários do client |
| `cacert.pem` | Certificado SSL |
| `*.log` | Logs |
| `data/things/` | Sprites/DAT (muito grandes) |
| `data/sounds/` | Sons (muito grandes) |
| `data/setup.otml` | Configurações do usuário |
| `data/minimap.*` | Minimap do usuário |
| `generate_manifest.ps1` | Script interno (não vai pro jogador) |

---

## Comandos Úteis do Git

```powershell
# Ver status dos arquivos alterados
git status

# Ver histórico de commits
git log --oneline -10

# Desfazer alterações em um arquivo (CUIDADO: perde as mudanças)
git checkout -- caminho/do/arquivo.lua

# Ver diferenças antes de commitar
git diff
```

---

## Links

- **Repositório:** https://github.com/andre78451200-cloud/MoouseOT_Client
- **Download (Release):** https://github.com/andre78451200-cloud/MoouseOT_Client/releases
- **Site:** https://www.moouseot.com.br
