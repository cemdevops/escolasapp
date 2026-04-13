# Fase 2 - Compilação Angular e Testes

## 🎯 Objetivo
1. Compilar Angular (npm run build)
2. Testar REST APIs
3. Validar MongoDB connectivity
4. Documentar resultados

---

## 📋 Passo 1: Conectar ao Vagrant via SSH

```bash
# Terminal Windows (PowerShell)
ssh -p 2222 -l vagrant -i '.vagrant\machines\default\virtualbox\private_key' localhost
```

Você será conectado à VM Ubuntu 20.04.

---

## 📋 Passo 2: Verificar Status dos Containers

```bash
# Dentro da VM
cd /home/vagrant/escolasapp
docker compose ps
```

**Saída esperada:**
```
CONTAINER ID   IMAGE           STATUS          PORTS
xxxxx          escolasapp:dev  Up (healthy)    0.0.0.0:3002->3002/tcp
xxxxx          mongo:3.6       Up (healthy)    0.0.0.0:27017->27017/tcp
```

Se não estiverem rodando:
```bash
COMPOSE_PROFILES=dev docker-compose up -d
```

---

## 📋 Passo 3: Tentar Compilar Angular

```bash
# Dentro da VM
cd /home/vagrant/escolasapp
docker compose exec app-dev bash
```

Você estará **dentro do container**. Agora execute:

```bash
# Dentro do container
npm run build 2>&1 | tee build.log
```

### Possíveis Resultados:

**Cenário A - BUILD COM SUCESSO ✅**
```
✔ Angular build completed successfully
dist/ folder will be populated
```
Próximo passo: [Ir para Passo 5](#passo-5-testar-apis)

**Cenário B - ERRO DE COMPILAÇÃO ❌**
```
error TS1109: Expression expected
error TS1005: '...' expected
```
Próximo passo: [Ir para Passo 4](#passo-4-se-build-falhar)

---

## 📋 Passo 4: Se Build Falhar

Se receber erros de TypeScript, tente:

```bash
# Dentro do container
npm install --legacy-peer-deps --force
npm run build
```

Se ainda falhar:

```bash
# Sair do container
exit

# Do host, criar dist/index.html estaticamente
```

---

## 📋 Passo 5: Testar APIs

```bash
# De fora do container, no host Windows
# Teste cada endpoint:

curl http://localhost:3002/school
curl http://localhost:3002/weightingarea
curl http://localhost:3002/ap-secvariable
curl http://localhost:3002/br-sp-rmsp-secvariable
```

### Ou use Postman/Browser:
- GET http://localhost:3002/school
- GET http://localhost:3002/weightingarea
- GET http://localhost:3002/ap-secvariable
- GET http://localhost:3002/br-sp-rmsp-secvariable

---

## 📋 Passo 6: Validar MongoDB

```bash
# Dentro da VM (fora do container)
docker compose logs mongodb | tail -50
```

Procure por: `waiting for connections on port 27017`

---

## 📋 Passo 7: Verificar Conectividade App ↔ MongoDB

```bash
# Dentro do container app-dev
curl http://localhost:27017
```

Deve retornar algo como:
```
It looks like you are trying to access MongoDB over HTTP on the native driver port.
```

Isso indica que a conexão é viável.

---

## 📝 Próximas Ações Após Testes

- [ ] ng build completou com sucesso
- [ ] APIs respondendo (GET /school, etc)
- [ ] MongoDB respondendo
- [ ] Re-habilitar Ansible provisioning
- [ ] Testar profiles (staging/prod)
- [ ] Commit de resultados

---

## 🔧 Troubleshooting

### Erro: "Cannot find module"
```bash
npm install --legacy-peer-deps
```

### Erro: "ng: command not found"
```bash
npm install -g @angular/cli@5
```

### Container não inicia
```bash
docker compose down -v
COMPOSE_PROFILES=dev docker-compose up -d --build
```

### Port 3002 já está em uso
```bash
lsof -i :3002  # Listar processo usando porta
docker compose restart app-dev
```

---

## 📊 Log de Execução

Execute os passos acima e anote os resultados aqui:

- [ ] Passo 1: SSH conectado ✓
- [ ] Passo 2: Containers rodando ✓
- [ ] Passo 3: ng build [resultado]
- [ ] Passo 5: APIs testadas [resultado]
- [ ] Passo 6: MongoDB logs [resultado]
- [ ] Passo 7: App ↔ MongoDB [resultado]
