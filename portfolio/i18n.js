const I18N = {
  es: {
    'html.lang': 'es',
    'meta.title': 'ERC-20 + EIP-2612 Permit — Rolando Strahm',
    'meta.description':
      'Token ERC-20 production-ready con Permit, optimización de gas y verificación defensiva de ataques (SWC). Foundry · Solidity 0.8.24.',

    'nav.overview': 'Proyecto',
    'nav.pillars': 'Pilares',
    'nav.gas': 'Gas',
    'nav.swc': 'SWC',
    'nav.process': 'Proceso',
    'nav.attacks': 'Ataques',
    'nav.repos': 'Repos',
    'nav.close': '← Cerrar',

    'hero.tag': '// MÓDULO 01 · PORTFOLIO WEB3',
    'hero.title': 'ERC-20 + EIP-2612<br>PERMIT TOKEN',
    'hero.role': 'Solidity 0.8.24 · Foundry · Gas · SWC',
    'hero.sub':
      'Token fungible production-ready con aprobaciones gasless, optimización de gas documentada y campañas defensivas contra vectores del SWC Registry.',
    'hero.cta1': 'Ver en GitHub',
    'hero.cta2': 'Ver en GitLab',

    'ov.eyebrow': '// 01 — CONTEXTO',
    'ov.title': 'Por qué este proyecto',
    'ov.lead':
      'Para no oxidar mis conocimientos en <strong>Solidity</strong>, volví a implementar contratos desde cero con Foundry. Este módulo no es solo un ERC-20: cierra el ciclo con <strong>optimización de gas</strong> y <strong>verificación de ataques</strong> — las dos capas que más me interesan en smart contracts de producción.',

    'pi.eyebrow': '// 02 — TRES PILARES',
    'pi.title': 'Qué entrega el módulo',
    'p1.num': '// PILAR_01',
    'p1.title': 'ERC-20 + Permit',
    'p1.desc':
      'Implementación propia de IERC20 e IERC20Permit: transferencias, allowances y aprobaciones gasless vía EIP-712 / ecrecover.',
    'p1.l1': 'Domain separator fork-safe',
    'p1.l2': 'Custom errors (sin require strings)',
    'p1.l3': 'Patrón CEI estricto',
    'p2.num': '// PILAR_02',
    'p2.title': 'Optimización de gas',
    'p2.desc':
      'Immutables, constants, unchecked solo tras validar bounds, allowance infinita y typehashes cacheados.',
    'p2.l1': 'decimals / chainId / domain immutable',
    'p2.l2': 'PERMIT_TYPEHASH constant',
    'p2.l3': 'Gas report con Foundry',
    'p3.num': '// PILAR_03',
    'p3.title': 'Verificación de ataques',
    'p3.desc':
      'Matriz SWC-100–136 y campañas A–E: tests defensivos donde el ataque debe fallar, más casos documentales del estándar.',
    'p3.l1': 'Replay / malleabilidad / fork',
    'p3.l2': 'Integridad balance & allowance',
    'p3.l3': '0 vulnerabilidades SWC explotables',

    'gas.eyebrow': '// 03 — OPTIMIZACIÓN DE GAS',
    'gas.title': 'Menos SLOAD, más control',
    'gas.lead':
      'Fase 4 del módulo: cada optimización está documentada con su <strong>tradeoff</strong> en NatSpec. El objetivo no es micro-ahorros ciegos, sino lecturas baratas en el hot path y aritmética <code>unchecked</code> solo donde el bound ya está validado.',
    'gas.th1': 'Optimización',
    'gas.th2': 'Tradeoff / efecto',
    'gas.r1a': 'Immutables: decimals, INITIAL_CHAIN_ID, INITIAL_DOMAIN_SEPARATOR',
    'gas.r1b': 'Lecturas ~100 gas vs ~2100 SLOAD en storage',
    'gas.r2a': 'PERMIT_TYPEHASH / _DOMAIN_TYPEHASH / _VERSION_HASH constant',
    'gas.r2b': 'Menos keccak en runtime; ligero aumento de bytecode',
    'gas.r3a': '_NAME_HASH immutable',
    'gas.r3b': 'Evita releer string storage al recomputar domain separator en forks',
    'gas.r4a': '_buildDomainSeparator(chainId) unificado',
    'gas.r4b': 'Constructor y forks comparten la misma lógica',
    'gas.r5a': 'Allowance type(uint256).max sin decremento',
    'gas.r5b': '~5k gas menos por transferFrom; patrón DeFi estándar',
    'gas.r6a': 'unchecked en balances / nonces / allowance',
    'gas.r6b': 'Sin overflow checks redundantes tras validación explícita',
    'gas.r7a': 'Funciones external + custom errors',
    'gas.r7b': 'ABI más barato y reverts compactos vs require con strings',

    'swc.eyebrow': '// 04 — VERIFICACIÓN SWC',
    'swc.title': 'SWC Registry · EIP-1470',
    'swc.lead':
      'Fase 8: matriz completa <strong>SWC-100 → SWC-136</strong> contra <code>ERC20PermitToken</code>. Informe en <code>doc/SWC-AUDIT-ES.md</code>. Conclusión: <strong>0 vulnerabilidades explotables</strong> en el alcance del token.',
    'swc.s1': 'Mitigados / N/A',
    'swc.s2': 'Informativos (diseño)',
    'swc.s3': 'Vulnerables',
    'swc.th1': 'SWC clave',
    'swc.th2': 'Mitigación en el contrato',
    'swc.r101': 'Integer overflow: Solidity 0.8.24 + checks antes de unchecked',
    'swc.r103': 'Floating pragma: pragma solidity 0.8.24 fijo',
    'swc.r107': 'Reentrancy: CEI estricto; sin external calls ni callbacks',
    'swc.r117': 'Signature malleability: rechazo s > secp256k1 half-order (EIP-2)',
    'swc.r121': 'Signature replay: nonces + DOMAIN_SEPARATOR con chainId',
    'swc.r122': 'Firma inválida: ecrecover + recovered == owner + ≠ address(0)',
    'swc.info': 'INFORMATIVO',
    'swc.i1t': 'Approve front-running',
    'swc.i1d':
      'Limitación del estándar ERC-20. Mitigación de producto: permit en un solo paso o approve(0) antes de cambiar allowance.',
    'swc.i2t': 'Permit relayer',
    'swc.i2d':
      'Cualquiera puede enviar una firma válida (by design). No es un bug si la firma solo expresa allowance.',

    'pr.eyebrow': '// 05 — PROCESO',
    'pr.title': 'Fases 0–8 cerradas',
    'pr.lead':
      'Desarrollo por gates de aprobación: bootstrap Foundry, interfaces, core ERC-20, Permit, gas, unit/fuzz tests, revisión final y auditoría SWC.',
    'ph.0': 'Bootstrap Foundry',
    'ph.12': 'Interfaces + ERC-20 core',
    'ph.34': 'Permit + gas',
    'ph.56': 'Unit + fuzz tests',
    'ph.78': 'Review + SWC audit',
    'st.1': 'Fases',
    'st.2': 'Campañas',
    'st.3': 'SWC críticos',
    'st.4': 'Tests Attack*',
    'term.label': 'rolando@strahm:~/01-erc20',
    'term.1': 'forge test --match-test test_Attack',
    'term.2': '[PASS] suite · 8 passed',
    'term.3': 'cat doc/SWC-AUDIT-ES.md | head',
    'term.4': 'Vulnerable: 0 · Informativos: 2 · Mitigados/N/A: 34',
    'term.5': 'echo status',
    'term.6': 'MODULE_01_CLOSED · ATTACK_CAMPAIGNS_CLOSED',

    'at.eyebrow': '// 06 — CAMPAÑAS DE ATAQUE',
    'at.title': 'Defensivo, no ofensivo',
    'at.lead':
      'Cada campaña se implementó como tests Foundry donde el éxito del “ataque” es que falle. Sin PoCs de exploit: integridad, firmas, orden de txs (diseño ERC-20), aritmética unchecked y superficie vacía.',
    'cA.t': 'Integridad',
    'cA.d': 'Balance, allowance y address(0).',
    'cB.t': 'Firmas',
    'cB.d': 'Replay, chainId, v inválido, malleabilidad.',
    'cC.t': 'Orden txs',
    'cC.d': 'Approve race y relayer de permit (estándar).',
    'cD.t': 'Unchecked',
    'cD.d': 'Vaciado exacto sin romper totalSupply.',
    'cE.t': 'N/A',
    'cE.d': 'Sin ETH, selfdestruct, delegatecall, reentrancy.',

    're.eyebrow': '// 07 — CÓDIGO ABIERTO',
    're.title': 'Repositorios',
    're.lead':
      'El mismo código está publicado en GitHub y GitLab. Contrato, tests, fases, auditoría SWC y campañas de ataque.',
    're.cta': 'Contactar',
    're.linkedin': 'LinkedIn',

    'ft.left': 'ROLANDO STRAHM — ERC-20 + EIP-2612 · Portfolio',
    'ft.right': 'FOUNDRY · SOLC 0.8.24 · ALL_SYSTEMS_OPERATIONAL',
  },

  en: {
    'html.lang': 'en',
    'meta.title': 'ERC-20 + EIP-2612 Permit — Rolando Strahm',
    'meta.description':
      'Production-ready ERC-20 token with Permit, gas optimization, and defensive attack verification (SWC). Foundry · Solidity 0.8.24.',

    'nav.overview': 'Project',
    'nav.pillars': 'Pillars',
    'nav.gas': 'Gas',
    'nav.swc': 'SWC',
    'nav.process': 'Process',
    'nav.attacks': 'Attacks',
    'nav.repos': 'Repos',
    'nav.close': '← Close',

    'hero.tag': '// MODULE 01 · WEB3 PORTFOLIO',
    'hero.title': 'ERC-20 + EIP-2612<br>PERMIT TOKEN',
    'hero.role': 'Solidity 0.8.24 · Foundry · Gas · SWC',
    'hero.sub':
      'Production-ready fungible token with gasless approvals, documented gas optimizations, and defensive campaigns against SWC Registry vectors.',
    'hero.cta1': 'View on GitHub',
    'hero.cta2': 'View on GitLab',

    'ov.eyebrow': '// 01 — CONTEXT',
    'ov.title': 'Why this project',
    'ov.lead':
      'To keep my <strong>Solidity</strong> skills sharp, I rebuilt contracts from scratch with Foundry. This module is more than an ERC-20: it closes the loop with <strong>gas optimization</strong> and <strong>attack verification</strong> — the two layers I care most about in production smart contracts.',

    'pi.eyebrow': '// 02 — THREE PILLARS',
    'pi.title': 'What the module ships',
    'p1.num': '// PILLAR_01',
    'p1.title': 'ERC-20 + Permit',
    'p1.desc':
      'Custom IERC20 and IERC20Permit: transfers, allowances, and gasless approvals via EIP-712 / ecrecover.',
    'p1.l1': 'Fork-safe domain separator',
    'p1.l2': 'Custom errors (no require strings)',
    'p1.l3': 'Strict CEI pattern',
    'p2.num': '// PILLAR_02',
    'p2.title': 'Gas optimization',
    'p2.desc':
      'Immutables, constants, unchecked only after bound checks, infinite allowance, and cached typehashes.',
    'p2.l1': 'decimals / chainId / domain immutable',
    'p2.l2': 'PERMIT_TYPEHASH constant',
    'p2.l3': 'Foundry gas report',
    'p3.num': '// PILLAR_03',
    'p3.title': 'Attack verification',
    'p3.desc':
      'SWC-100–136 matrix and campaigns A–E: defensive tests where the attack must fail, plus documentary standard cases.',
    'p3.l1': 'Replay / malleability / fork',
    'p3.l2': 'Balance & allowance integrity',
    'p3.l3': '0 exploitable SWC findings',

    'gas.eyebrow': '// 03 — GAS OPTIMIZATION',
    'gas.title': 'Fewer SLOADs, more control',
    'gas.lead':
      'Module phase 4: every optimization is documented with its <strong>tradeoff</strong> in NatSpec. The goal is not blind micro-savings, but cheap reads on the hot path and <code>unchecked</code> arithmetic only where bounds are already validated.',
    'gas.th1': 'Optimization',
    'gas.th2': 'Tradeoff / effect',
    'gas.r1a': 'Immutables: decimals, INITIAL_CHAIN_ID, INITIAL_DOMAIN_SEPARATOR',
    'gas.r1b': 'Reads ~100 gas vs ~2100 SLOAD from storage',
    'gas.r2a': 'PERMIT_TYPEHASH / _DOMAIN_TYPEHASH / _VERSION_HASH constant',
    'gas.r2b': 'Fewer keccak at runtime; slight bytecode increase',
    'gas.r3a': '_NAME_HASH immutable',
    'gas.r3b': 'Avoids re-reading string storage when recomputing domain separator on forks',
    'gas.r4a': 'Unified _buildDomainSeparator(chainId)',
    'gas.r4b': 'Constructor and forks share the same logic',
    'gas.r5a': 'type(uint256).max allowance without decrement',
    'gas.r5b': '~5k gas less per transferFrom; standard DeFi pattern',
    'gas.r6a': 'unchecked for balances / nonces / allowance',
    'gas.r6b': 'No redundant overflow checks after explicit validation',
    'gas.r7a': 'external functions + custom errors',
    'gas.r7b': 'Cheaper ABI and compact reverts vs require strings',

    'swc.eyebrow': '// 04 — SWC VERIFICATION',
    'swc.title': 'SWC Registry · EIP-1470',
    'swc.lead':
      'Phase 8: full matrix <strong>SWC-100 → SWC-136</strong> against <code>ERC20PermitToken</code>. Report in <code>doc/SWC-AUDIT-EN.md</code>. Conclusion: <strong>0 exploitable vulnerabilities</strong> in the token scope.',
    'swc.s1': 'Mitigated / N/A',
    'swc.s2': 'Informational (design)',
    'swc.s3': 'Vulnerable',
    'swc.th1': 'Key SWC',
    'swc.th2': 'Mitigation in the contract',
    'swc.r101': 'Integer overflow: Solidity 0.8.24 + checks before unchecked',
    'swc.r103': 'Floating pragma: fixed pragma solidity 0.8.24',
    'swc.r107': 'Reentrancy: strict CEI; no external calls or callbacks',
    'swc.r117': 'Signature malleability: reject s > secp256k1 half-order (EIP-2)',
    'swc.r121': 'Signature replay: nonces + DOMAIN_SEPARATOR with chainId',
    'swc.r122': 'Invalid signature: ecrecover + recovered == owner + ≠ address(0)',
    'swc.info': 'INFORMATIONAL',
    'swc.i1t': 'Approve front-running',
    'swc.i1d':
      'ERC-20 standard limitation. Product mitigation: single-step permit or approve(0) before changing allowance.',
    'swc.i2t': 'Permit relayer',
    'swc.i2d':
      'Anyone can submit a valid signature (by design). Not a bug if the signature only expresses an allowance.',

    'pr.eyebrow': '// 05 — PROCESS',
    'pr.title': 'Phases 0–8 closed',
    'pr.lead':
      'Approval-gated delivery: Foundry bootstrap, interfaces, ERC-20 core, Permit, gas, unit/fuzz tests, final review, and SWC audit.',
    'ph.0': 'Foundry bootstrap',
    'ph.12': 'Interfaces + ERC-20 core',
    'ph.34': 'Permit + gas',
    'ph.56': 'Unit + fuzz tests',
    'ph.78': 'Review + SWC audit',
    'st.1': 'Phases',
    'st.2': 'Campaigns',
    'st.3': 'Critical SWC',
    'st.4': 'Attack* tests',
    'term.label': 'rolando@strahm:~/01-erc20',
    'term.1': 'forge test --match-test test_Attack',
    'term.2': '[PASS] suite · 8 passed',
    'term.3': 'cat doc/SWC-AUDIT-EN.md | head',
    'term.4': 'Vulnerable: 0 · Informational: 2 · Mitigated/N/A: 34',
    'term.5': 'echo status',
    'term.6': 'MODULE_01_CLOSED · ATTACK_CAMPAIGNS_CLOSED',

    'at.eyebrow': '// 06 — ATTACK CAMPAIGNS',
    'at.title': 'Defensive, not offensive',
    'at.lead':
      'Each campaign is Foundry tests where a successful “attack” means it fails. No exploit PoCs: integrity, signatures, tx ordering (ERC-20 design), unchecked math, and empty attack surface.',
    'cA.t': 'Integrity',
    'cA.d': 'Balance, allowance, and address(0).',
    'cB.t': 'Signatures',
    'cB.d': 'Replay, chainId, invalid v, malleability.',
    'cC.t': 'Tx order',
    'cC.d': 'Approve race and permit relayer (standard).',
    'cD.t': 'Unchecked',
    'cD.d': 'Exact drain without breaking totalSupply.',
    'cE.t': 'N/A',
    'cE.d': 'No ETH, selfdestruct, delegatecall, reentrancy.',

    're.eyebrow': '// 07 — OPEN SOURCE',
    're.title': 'Repositories',
    're.lead':
      'The same codebase is published on GitHub and GitLab: contract, tests, phases, SWC audit, and attack campaigns.',
    're.cta': 'Contact',
    're.linkedin': 'LinkedIn',

    'ft.left': 'ROLANDO STRAHM — ERC-20 + EIP-2612 · Portfolio',
    'ft.right': 'FOUNDRY · SOLC 0.8.24 · ALL_SYSTEMS_OPERATIONAL',
  },
};

function setLanguage(lang) {
  const dict = I18N[lang] || I18N.es;
  document.documentElement.lang = dict['html.lang'];
  document.title = dict['meta.title'];

  const metaDesc = document.querySelector('meta[name="description"]');
  if (metaDesc && dict['meta.description']) {
    metaDesc.setAttribute('content', dict['meta.description']);
  }

  document.querySelectorAll('[data-i18n]').forEach((el) => {
    const key = el.getAttribute('data-i18n');
    const val = dict[key];
    if (val == null) return;
    if (el.hasAttribute('data-i18n-html')) el.innerHTML = val;
    else el.textContent = val;
  });

  document.querySelectorAll('.lang-btn').forEach((btn) => {
    btn.classList.toggle('active', btn.dataset.lang === lang);
  });

  localStorage.setItem('erc20-portfolio-lang', lang);

  const url = new URL(window.location.href);
  url.searchParams.set('lang', lang);
  history.replaceState(null, '', url);
}

function initI18n() {
  const params = new URLSearchParams(window.location.search);
  const fromQuery = params.get('lang');
  const saved = localStorage.getItem('erc20-portfolio-lang');
  const preferred =
    (fromQuery === 'en' || fromQuery === 'es' ? fromQuery : null) ||
    saved ||
    (navigator.language?.startsWith('en') ? 'en' : 'es');

  setLanguage(preferred);

  document.querySelectorAll('.lang-btn').forEach((btn) => {
    btn.addEventListener('click', () => setLanguage(btn.dataset.lang));
  });
}

document.addEventListener('DOMContentLoaded', initI18n);
