## Foundry

> English version: [`README-EN.md`](README-EN.md)

**Foundry es un toolkit ultrarrápido, portable y modular para el desarrollo de aplicaciones en Ethereum, escrito en Rust.**

Foundry se compone de:

- **Forge**: framework de testing para Ethereum (como Truffle, Hardhat y DappTools).
- **Cast**: navaja suiza para interactuar con smart contracts EVM, enviar transacciones y obtener datos de la chain.
- **Anvil**: nodo local de Ethereum, similar a Ganache o Hardhat Network.
- **Chisel**: REPL de Solidity rápido, utilitario y detallado.

## Documentación

https://book.getfoundry.sh/

## Uso

### Compilar

```shell
$ forge build
```

### Tests

```shell
$ forge test
```

### Formatear

```shell
$ forge fmt
```

### Snapshots de gas

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Ayuda

```shell
$ forge --help
$ anvil --help
$ cast --help
```
