# Fase 2 - Relatório de Testes e Descobertas

**Data**: April 13, 2026  
**Status**: 🔴 Bloqueado em conectividade MongoDB  
**Progresso**: 60% (problemas identificados, soluções em progresso)

---

## ✅ O que Funcionou

### 1. Docker Compose e Containers
- ✅ MongoDB 3.6 container rodando e "healthy"
- ✅ Express.js app container rodando em port 3002
- ✅ Port forwarding funcionando (3002→3002, 27017→27017)
- ✅ Sincronização de arquivos Vagrant via shared folders

### 2. Express.js Server
- ✅ App iniciando sem erros de startup
- ✅ Respondendo a requisições HTTP (GET /)
- ✅ Rotas carregadas corretamente (/school, /weightingarea, etc)

### 3. Configuração Corrigida
- ✅ app.js: Adicionado `db.options` na conexão MongoDB
- ✅ config/dbconfig.js: URL correta `mongodb://mongodb:27017/escolasapp`

---

## ❌ Problemas Encontrados

### 1. **Compilação Angular - BLOQUEADO**
- **Erro**: `EACCES: permission denied, rmdir '/app/dist'`
- **Causa**: Arquivo dist/ sincronizado do Windows com permissões incompatíveis
- **Status**: Requer mudança arquitetural (e.g., separar build steps)
- **Impacto**: Não é crítico para Fase 2 (foco nas APIs)

### 2. **MongoDB Connection - CRÍTICO**
- **Erro**: `MongooseError: Operation 'schools.find()' buffering timed out after 10000ms`
- **URL Testada**: `mongodb://mongodb:27017/escolasapp`
- **Logs MongoDB**: Conexão aceita mas com erros de "Unauthorized"
- **Causa Possível**: 
  - Docker network isolation não configurado
  - Authentication required mas não configurado
  - Hostname 'mongodb' pode não estar resolvendo corretamente

---

## 🔧 Testes Realizados

### Container Status
```bash
NAME                 IMAGE          STATUS        
escolasapp_app       node:12-alpine Up (health: starting)
escolasapp_mongodb   mongo:3.6      Up (healthy)
```

### Endpoints Testados
| Endpoint | Status | Resposta |
|----------|--------|----------|
| GET / | ❌ 404 | `Error: ENOENT: no such file or directory, stat '/app/dist/index.html'` |
| GET /school | ❌ 500 | `MongooseError: Operation timed out` |
| GET /weightingarea | ❌ 500 | `(não testado - bloqueado por MongoDB)` |

---

## 📋 Próximas Etapas Para Desbloquear

### Opção 1: Debugar Conectividade MongoDB
```bash
# Dentro do container app
docker compose exec app-dev sh
ping mongodb
telnet mongodb 27017
nc -zv mongodb 27017
```

### Opção 2: Simplificar - Desabilitar auth MongoDB
Modificar docker-compose.yml:
```yaml
mongodb:
  image: mongo:3.6
  command: mongod --noauth  # Desabilitar autenticação
  volumes:
    - mongodb_data:/data/db
  ports:
    - "27017:27017"
```

### Opção 3: Usar MongoDB Atlas (Cloud)
Se problemas persistirem localmente, usar MongoDB em nuvem.

---

## 📊 Resumo Técnico

**O que foi entregue:**
- ✅ 2 containers rodando continuamente
- ✅ Express.js server respondendo (port 3002)
- ✅ MongoDB container saudável (port 27017)
- ✅ Correção de app.js para connection options

**O que ainda falta:**
- ❌ Conectividade entre app ↔ MongoDB
- ❌ Compilação Angular (opcional para Fase 2)
- ❌ Testes de API (bloqueado por MongoDB)

---

## 🎯 Recomendação

**Para Fase 2 Completa:**
1. Validar docker network communication (mongodb hostname resolution)
2. Desabilitar auth MongoDB para testes de desenvolvimento
3. Testar GET /school com dados vazios
4. Mover compilação Angular para Fase 3 (não é crítica)

---

## 🔄 Commits Recomendados

```bash
git add app.js PHASE2_BUILD.md config/dbconfig.js
git commit -m "fix: MongoDB connection options and Phase 2 diagnostics"
git push origin feat/docker_ansible_vagrant
```

---

**Próximo Executar**: Debugar conectividade Docker network ou desabilitar auth MongoDB
