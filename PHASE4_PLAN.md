# Fase 4 - Angular SPA (Modernização e Build)

**Data**: April 13, 2026  
**Status**: IN PROGRESS  
**Objetivo**: Compilar Angular 5 SPA e servir estaticamente OU modernizar para Angular 15  

---

## 📋 Situação Atual

### Dependências Angular:
- **Angular**: 5.2.9 (end-of-life desde 2018)
- **@agm/core**: ~1.0.0-beta.2 (requer Angular 6+) ← **CONFLITO CRÍTICO**
- **TypeScript**: ^2.4.2 (desatualizado)
- **Node.js**: 12-Alpine (compatível com Angular 5)
- **Build tool**: ng cli (incluído em dependencies)

### Problemas Identificados:
1. **Incompatibilidade de dependências**: @agm/core 1.0.0-beta.2 não suporta Angular 5
   - @agm/core requer Angular 6.0 mínimo
   - Angular 5 entrou em LTS apenas até abril 2018
   
2. **npm install issues** no Vagrant shared folder
   - File system corruption (acorn-dynamic-import)
   - Solution: Docker-based build evita shared folder issues

3. **TypeScript versioning**: Conflitos com versões antigas

---

## 🎯 3 Caminhos Possíveis

### **OPÇÃO 1: Downgrade @agm/core (Rápido - 30min)**
**Vantagem**: Mantém Angular 5 sem major refactoring  
**Desvantagem**: @agm/core beta version, sem suporte

```bash
npm install @agm/core@1.0.0-beta.2 --force
ng build --prod
```

**Status**: ⚠️ Viável mas não recomendado (beta package)

---

### **OPÇÃO 2: Docker-only Build (Prático - 45min)** 🟢 RECOMENDADO
**Vantagem**: Evita issues de shared folder, build automatizado no container  
**Desvantagem**: Precisa de Docker para builds (já temos)

**Processo**:
1. Criar stage de build no Dockerfile
2. Compilar Angular 5 com `ng build` dentro do container
3. Servir dist/ como static files no Express
4. Output: SPA compilada + API integrada

**Status**: ✅ Altamente viável (recomendado)

---

### **OPÇÃO 3: Angular 5 → 15 Upgrade (Completo - 8-12 horas)**
**Vantagem**: Moderno, full support, futuro-proof  
**Desvantagem**: Major refactoring, breaking changes

**Mudanças necessárias**:
- @agm/core → @angular/google-maps (novo package)
- RxJS ~5.5 → ~7.x (operadores renomeados)
- Material ^5 → ^15 (API changes)
- Package @ng-bootstrap ajustes
- Standalone components (novo paradigma)
- TypeScript ^3.x → ^5.x

**Estimativa**: 2-3 dias de trabalho  
**Status**: ❌ Muito complexo para agora

---

## 🚀 Recomendação: OPÇÃO 2 (Docker Build)

### Por quê?
1. ✅ Rápido (45 minutos)
2. ✅ Evita Vagrant shared folder issues
3. ✅ Build reproducível (mesmos resultados)
4. ✅ Integra SPA com backend (Express static)
5. ✅ CI/CD ready (mesmo processo funciona em produção)

### Implementação:
```dockerfile
# Stage 1: Build Angular
FROM node:12-alpine AS angular-builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm install --legacy-peer-deps
COPY . .
RUN npm run build

# Stage 2: Serve com Express (já existe)
FROM node:12-alpine
COPY --from=angular-builder /app/dist /app/src/dist
# Express serve dist/ como static
```

### Express Integration:
```javascript
// app.js
app.use(express.static('src/dist'));
app.get('*', (req, res) => res.sendFile('src/dist/index.html'));
```

---

## 📝 Próximos Passos

**Se escolher OPÇÃO 2**:
1. ✅ Update Dockerfile multi-stage build
2. ✅ Update docker-compose.yml (add build triggers)
3. ✅ Update app.js (serve static SPA)
4. ✅ Test build no Docker
5. ✅ Validate SPA + API integration
6. ✅ Git commit

**Tempo estimado**: 45 minutos

---

## ❓ Qual opção você prefere?
- **Opção 1**: Downgrade (rápido mas não ideal)
- **Opção 2**: Docker Build ← RECOMENDADO
- **Opção 3**: Angular 5→15 (futuro)
- **Opção 4**: Skip SPA (manter API-only)

**Aguardando sua decisão para prosseguir!**
