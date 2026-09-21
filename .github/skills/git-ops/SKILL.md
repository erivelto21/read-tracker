---
name: git-ops
description: Commits semânticos, PRs e branches. Use para criar mensagens de commit, descrever PRs ou nomear branches.
---

# Git Ops

Skill para padronizar operacoes git com foco em commits semanticos, descricoes
de PR/MR e convencao de branches.

Toda saida desta skill DEVE seguir estas regras globais:
- Texto em caixa baixa (lowercase), exceto siglas e nomes proprios quando inevitavel
- Sem acentos ou caracteres especiais no texto gerado
- Idioma do commit/branch: ingles (padrao da comunidade)
- Idioma da descricao do PR/MR: seguir o idioma do projeto ou do template existente

## 1. Commits semanticos

### Formato

```
<tipo>(<escopo opcional>): <descricao>

<corpo opcional>

<rodape opcional>
```

### Tipos permitidos

| tipo       | quando usar                                              |
|------------|----------------------------------------------------------|
| feat       | nova funcionalidade                                      |
| fix        | correcao de bug                                          |
| docs       | apenas documentacao                                      |
| style      | formatacao, ponto e virgula, espacos (sem logica)        |
| refactor   | reestruturacao sem mudar comportamento                   |
| perf       | melhoria de performance                                  |
| test       | adicionar ou corrigir testes                             |
| build      | build system, dependencias (npm, pip, gradle)            |
| ci         | configuracao de ci/cd (github actions, jenkins, gitlab)  |
| chore      | tarefas de manutencao que nao se encaixam acima          |
| revert     | reverter um commit anterior                              |

### Regras do subject line

- ALVO: 50 caracteres totais (incluindo tipo e escopo)
- LIMITE MAXIMO: 72 caracteres (OBRIGATORIO — GitLab CI rejeita mensagens maiores)
- Modo imperativo: "add", "fix", "remove" (nao "added", "fixing", "removes")
- Sem ponto final
- Tudo em caixa baixa
- Sem acentos

### Validacao do subject line

Antes de finalizar qualquer mensagem de commit, VALIDAR o tamanho:
- Contar TODOS os caracteres do subject (incluindo "tipo:", "(escopo): ", e a descricao)
- Se > 72 caracteres: ABREVIAR usando as tecnicas abaixo
- Se > 50 caracteres: preferir encurtar para o alvo de 50

Tecnicas de abreviacao (priorizar nesta ordem):
1. Remover palavras desnecessarias: "the", "a", "an", "from", "to" (quando possivel)
2. Usar abreviacoes comuns: "image" → "img", "version" → "ver", "upgrade" → "upg"
3. Encurtar referencias: "python:3.11-bullseye" → "py3.11-bullseye", "python:3.12-slim-trixie" → "py3.12-trixie"
4. Reescrever com palavras mais curtas: "upgrade base image" → "bump base image", "add support for" → "add"

### Regras do corpo (opcional)

- Separar do subject por uma linha em branco
- Quebrar linhas em 72 caracteres
- Explicar O QUE e POR QUE, nao COMO
- Usar quando o subject sozinho nao for suficiente

### Rodape (opcional)

- Referencia a issues: `closes #123`, `fixes #456`, `refs #789`
- Breaking changes: iniciar com `BREAKING CHANGE:` ou usar `!` apos o tipo
- Exemplo: `feat(api)!: change auth endpoint response format`

### Exemplos

```
feat(auth): add jwt token refresh endpoint

fix: resolve race condition in request queue

docs(readme): add setup instructions for docker

refactor(parser): simplify ast node creation logic

the previous implementation used recursive calls
unnecessarily, causing stack overflow on large inputs.

closes #234

feat(api)!: change response format to json:api

BREAKING CHANGE: all endpoints now return json:api
compliant responses. clients using the old format
must be updated.
```

### Anti-padroes (evitar)

- `fix: fix bug` → seja especifico sobre o que foi corrigido
- `feat: update code` → descreva a funcionalidade adicionada
- `chore: changes` → descreva quais mudancas
- misturar concerns: um commit = uma mudanca logica

## 2. Nomes de branch

### Formato

```
<tipo>/<descricao-curta>
```

### Regras

- Usar hifen como separador (nao underscore ou camelCase)
- Caixa baixa, sem acentos
- Maximo 50 caracteres no total
- Incluir numero do ticket quando houver: `feat/123-add-user-profile`
- Descricao curta e significativa (2-4 palavras)

### Tipos de branch

| prefixo    | uso                                   |
|------------|---------------------------------------|
| feat/      | nova funcionalidade                   |
| fix/       | correcao de bug                       |
| hotfix/    | correcao urgente em producao          |
| docs/      | documentacao                          |
| refactor/  | reestruturacao de codigo              |
| test/      | adicao ou correcao de testes          |
| chore/     | tarefas de manutencao                 |
| release/   | preparacao de release                 |

### Exemplos

```
feat/add-user-authentication
fix/123-null-pointer-login
hotfix/payment-timeout
docs/api-endpoint-reference
refactor/simplify-order-service
```

## 3. Descricoes de PR/MR

### Antes de gerar a descricao

1. VERIFICAR se o projeto ja tem template:
   - GitHub: `.github/PULL_REQUEST_TEMPLATE.md` ou `.github/PULL_REQUEST_TEMPLATE/`
   - GitLab: `.gitlab/merge_request_templates/`
   - Bitbucket: verificar configuracao do repositorio
   - Raiz do projeto: `pull_request_template.md` ou `docs/pull_request_template.md`
2. Se template existir: USAR o template como base, preenchendo as secoes
3. Se nao existir: usar o template padrao abaixo

Para verificar templates existentes, execute:
```bash
# buscar templates de PR/MR no projeto
find . -maxdepth 3 -iname "*pull_request_template*" -o -iname "*merge_request_template*" 2>/dev/null
```

### Template padrao (quando nao houver template no projeto)

```markdown
## o que foi feito

<resumo claro e objetivo das mudancas, 2-3 frases>

## por que

<motivacao, contexto do problema, link para issue/ticket>

## como testar

<passos para o revisor validar as mudancas>

## checklist

- [ ] testes adicionados/atualizados
- [ ] documentacao atualizada (se aplicavel)
- [ ] sem breaking changes (ou documentado abaixo)
```

### Regras para descricao de PR/MR

- Titulo do PR segue o mesmo formato do commit semantico
- Corpo pode ser mais detalhado que o commit
- Referenciar issues/tickets relacionados
- Incluir contexto para o revisor (o que olhar primeiro, riscos conhecidos)
- Se houver breaking changes, documentar explicitamente
- Idioma: seguir o padrao do projeto/template existente

### Ao gerar descricoes de PR/MR

Perguntar ao usuario (se nao fornecido):
1. Quais mudancas foram feitas?
2. Qual o contexto/motivacao?
3. Ha algum ticket/issue relacionado?
4. Ha breaking changes?
5. Algo especifico para o revisor prestar atencao?

## 4. Referencia a issues e tickets

### Palavras-chave que fecham issues automaticamente

Estas palavras-chave funcionam no GitHub e GitLab quando usadas no commit ou PR:

```
closes #123
fixes #123
resolves #123
```

### Formato no commit

- No rodape do commit: `closes #123`
- Multiplas issues: `closes #123, closes #456`
- Referencia sem fechar: `refs #123` ou `see #123`

### Formato no PR/MR

- No corpo da descricao, vincular ao ticket/issue
- Usar a sintaxe da plataforma (GitHub: `#123`, Jira: `PROJECT-123`, etc)

## Fluxo de trabalho

Quando o usuario pedir ajuda com git, seguir este fluxo:

1. **Identificar a necessidade**: commit, branch, PR/MR, ou combinacao
2. **Coletar contexto**: o que foi feito, por que, qual o escopo
3. **Verificar templates**: se for PR/MR, buscar templates existentes no projeto
4. **Gerar saida**: aplicar todas as regras desta skill
5. **Validar**: confirmar que limites de caracteres e convencoes estao corretos

Para detalhes sobre cada tipo de commit e exemplos adicionais, consultar:
`references/commit-types-guide.md`
