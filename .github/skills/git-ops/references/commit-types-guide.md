# Guia de tipos de commit e exemplos

Referencia detalhada para casos de uso comuns e decisoes de tipo.

## Decisao de tipo: arvore de decisao

```
A mudanca adiciona funcionalidade nova?
  sim → feat
  nao →
    A mudanca corrige um bug?
      sim → fix
      nao →
        A mudanca afeta apenas documentacao?
          sim → docs
          nao →
            A mudanca melhora performance sem mudar comportamento?
              sim → perf
              nao →
                A mudanca reestrutura codigo sem mudar comportamento?
                  sim → refactor
                  nao →
                    A mudanca afeta apenas formatacao/estilo?
                      sim → style
                      nao →
                        A mudanca adiciona/corrige testes?
                          sim → test
                          nao →
                            A mudanca afeta build/dependencias?
                              sim → build
                              nao →
                                A mudanca afeta ci/cd?
                                  sim → ci
                                  nao → chore
```

## Exemplos por tipo

### feat
```
feat: add email notification on signup
feat(cart): implement quantity update
feat(api): add pagination to list endpoints
feat(auth)!: replace session with jwt tokens
```

### fix
```
fix: prevent duplicate form submission
fix(login): handle expired session redirect
fix(db): resolve connection pool exhaustion
fix(api): return 404 instead of 500 for missing user
```

### docs
```
docs: add contributing guidelines
docs(api): update authentication examples
docs(readme): add docker setup instructions
```

### style
```
style: fix indentation in config files
style(lint): apply prettier formatting rules
style: remove trailing whitespace
```

### refactor
```
refactor: extract validation into helper
refactor(auth): simplify token refresh logic
refactor(db): replace raw queries with orm
```

### perf
```
perf: lazy load dashboard components
perf(query): add index for user lookup
perf(api): cache frequently accessed endpoints
```

### test
```
test: add unit tests for cart service
test(auth): cover token expiration scenarios
test(e2e): add checkout flow tests
```

### build
```
build: upgrade webpack to v5
build(deps): bump axios from 0.21 to 1.6
build: add docker multi-stage build
```

### ci
```
ci: add github actions workflow for deploy
ci: fix flaky test retry in pipeline
ci(docker): optimize build cache layers
```

### chore
```
chore: update .gitignore for ide files
chore: remove deprecated feature flags
chore(deps): clean unused npm packages
```

### revert
```
revert: revert "feat: add email notification"

this reverts commit abc1234.
the feature caused smtp timeout issues in production.
```

## Casos ambiguos comuns

| situacao                                    | tipo correto | motivo                              |
|---------------------------------------------|-------------|-------------------------------------|
| atualizar versao de dependencia             | build       | afeta sistema de build              |
| adicionar .env.example                      | docs        | documentacao de configuracao        |
| renomear variavel para clareza              | style       | nao muda comportamento              |
| extrair metodo sem mudar comportamento      | refactor    | reestruturacao interna              |
| corrigir typo no codigo                     | fix         | se afeta comportamento              |
| corrigir typo na documentacao               | docs        | se e apenas texto                   |
| adicionar log para debug                    | chore       | manutencao/operacional              |
| remover codigo morto                        | refactor    | limpeza de codigo                   |
| atualizar snapshots de teste                | test        | manutencao de testes                |
| configurar pre-commit hooks                 | chore       | tooling do projeto                  |

## Escopo: quando usar

Usar escopo quando o projeto tem modulos/areas bem definidas:

- `feat(auth):` - mudancas no modulo de autenticacao
- `fix(payment):` - correcao no modulo de pagamento
- `docs(api):` - documentacao da api

NAO usar escopo quando:
- O projeto e pequeno e nao tem areas distintas
- O escopo nao ajuda a entender a mudanca
- O escopo e generico demais (ex: `feat(code):`)

## Breaking changes

Indicar de duas formas (podem ser combinadas):

1. `!` apos o tipo: `feat(api)!: change response format`
2. Footer: `BREAKING CHANGE: <descricao da quebra>`

Sempre incluir no corpo/footer:
- O que quebrou
- Como migrar/atualizar
- Versao anterior do comportamento
