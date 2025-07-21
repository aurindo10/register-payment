# Como Rodar o Projeto register-payment

Este tutorial descreve os passos para configurar e executar a aplicação `register-payment` localmente.

## Pré-requisitos

Antes de iniciar, certifique-se de que você tem os seguintes softwares instalados em seu sistema:

- **Java Development Kit (JDK) 17 ou superior:** Este projeto é construído com Java. Você pode verificar sua versão do Java executando `java -version` no terminal.
- **Maven:** O projeto utiliza o Maven Wrapper (`mvnw`), o que significa que você não precisa ter o Maven instalado globalmente. No entanto, ter uma instalação local pode ser útil para depuração.

## Passos para Rodar o Projeto

Siga os passos abaixo para colocar a aplicação em funcionamento:

1.  **Navegue até o Diretório do Projeto:**
    Abra seu terminal ou prompt de comando e navegue até o diretório raiz do projeto `register-payment`.

    ```bash
    cd /caminho/para/register-payment
    ```

    (Substitua `/caminho/para/register-payment` pelo caminho real onde você clonou ou extraiu o projeto.)

2.  **Construa o Projeto (Opcional, mas Recomendado):**
    É uma boa prática construir o projeto para garantir que todas as dependências sejam resolvidas e que o pacote executável seja gerado corretamente.

    ```bash
    ./mvnw clean install
    ```

    Este comando irá limpar quaisquer builds anteriores, compilar o código-fonte e baixar todas as dependências necessárias.

3.  **Execute a Aplicação Spring Boot:**
    Após a construção bem-sucedida, você pode iniciar a aplicação Spring Boot usando o Maven Wrapper:

    ```bash
    ./mvnw spring-boot:run
    ```

    Aguarde até que os logs no terminal indiquem que a aplicação foi iniciada com sucesso. Geralmente, você verá uma mensagem informando que o servidor embutido (Tomcat) foi iniciado na porta 8080 (a menos que configurado de forma diferente em `src/main/resources/application.properties`).

A aplicação agora estará rodando e pronta para ser acessada, normalmente em `http://localhost:8080`.
