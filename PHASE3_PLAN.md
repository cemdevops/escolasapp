# Fase 3 - Modernização Angular e Upgrade MongoDB

**Data**: April 13, 2026  
**Status**: 🔄 Em Progresso  
**Objetivos**: Angular build, MongoDB upgrade, staging/production preparação

---

## 📋 Tarefas Fase 3

### 1. Angular Compilation Challenge ⚠️
- **Status**: 🔄 Tentando
- **Problema Identificado**: 
  - Angular 5.2.9 vs @agm/core 1.1.0 (requer Angular 6+)
  - Conflitos de versão TypeScript
  - Dependências legacy
- **Solução**: 
  - `--legacy-peer-deps` + `--force`
  - Se falhar: usar apenas dist placeholder (SPA não crítica para backend tests)

### 2. MongoDB 3.6 → 5.0+ Upgrade
- **Status**: ⏳ Planejado
- **Razão**:
  - 3.6 end-of-life (February 2021)
  - 5.0+ melhor suporte a drivers modertos
  - Nova sintaxe de opções
- **Impacto**:
  - `retryWrites: true` funciona melhor
  - Melhor autenticação SCRAM-SHA-256
  - Connection pooling otimizado

### 3. Staging/Production Profiles
- **Status**: 🔄 Preparação
- **Desafios**:
  - Usar imagem do registry (ghcr.io/cemdevops/escolasapp)
  - Pipeline CI/CD para build + push
  - Environment variables por profile

### 4. Documentation & Testing
- **Status**: ⏳ Após compilação
- **Incluir**:
  - PHASE3_RESULTS.md
  - Deployment guide
  - Troubleshooting

---

## 🔧 Commands Reference

```bash
# Angular build (tentando):
npm run build

# MongoDB upgrade docker-compose update
# Mudar: mongo:3.6 → mongo:5.0

# Staging deploy (preparando):
docker compose --profile staging up -d

# Production deploy (preparando):
docker compose --profile production up -d
```

---

## 🎯 Success Criteria

- [ ] Angular SPA compila sem erros (ou documentar why it's deferred)
- [ ] MongoDB 5.0 container funciona com autenticação
- [ ] staging profile testa com sucesso (com registry mock)
- [ ] Todos endpoints responsivos
- [ ] Documentação Phase 3 completa
- [ ] 3+ git commits organized
