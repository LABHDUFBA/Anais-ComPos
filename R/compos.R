##############################################################################
###  Projeto de script para web scraping da página de [Anais da Associação  ##
###  Nacional dos Programas de Pós-Graduação em Comunicação - COMPÓS]       ##
###  desenvolvido pelo Laboratório de Humanidades Digitais da UFBA]         ## 
###                      (http://labhd.ufba.br/)                           ###    
##############################################################################


## Pacotes necessários
library(RSelenium)
library(tidyverse)
library(rvest)

####### Criando um Webdriver(Chromedriver) para o Rselenium
driver <- rsDriver(browser = c("chrome"),
                   # Note bem: uma das maiores fontes de erro 
                   # está na linha abaixo.
                   # o Chromedriver deve estar no PATH e deve
                   # ser a mesma versão instalada em sua máquina
                   # veja isto (https://www.youtube.com/watch?v=dz59GsdvUF8) 
                   #  sobre como instalar e configurar.
                   # Lembre de reiniciar sua máquina depois de
                   # configurar o PATH  
                   chromever="90.0.4430.24",  
                   port = 4447L)

remote_driver <- driver[["client"]]

#### Caso dê erro de porta já em uso execute a linha abaixo
#### ( retirando o "#" da linha)

# system("taskkill /im java.exe /f", intern=FALSE, ignore.stdout=FALSE)

## Acessando o site da Compos
remote_driver$navigate("https://www.compos.org.br/anais_encontros.php")
########################
### Pegando os links dos encontros
html <- remote_driver$getPageSource()[[1]]
links_enc <- html %>% 
  read_html() %>% 
  html_nodes(xpath = "//label/a") %>% 
  html_attr("href")
nome_encontros <- html %>% 
  read_html() %>% 
  html_nodes(xpath = "//label/a") %>% 
  html_text()

### Colando o endereço básico do site ("https://www.compos.org.br/") 
### da COMPÓS nos links dos encontros
links_enc <- paste0("https://www.compos.org.br/", links_enc, "")
### Criandos links para os GTs
links_gts <- gsub("menu_anais.php", "anais_texto_por_gt.php", links_enc)
### Criando um data-frame vazio para os links
df <- data.frame()
### Função de para clicar nos GTs
clica <- function(element){element$clickElement();  Sys.sleep(2);}
################################################################################
#### Loop para entrar nos GTs dos diferentes encontros, clicar nos diferentes ##
#### GT's e pegar a lista paras os PDF's                                      ##
################################################################################
for (i in 1:21){
  print(links_gts[i])
  url <- links_gts[i]
  remote_driver$navigate(url)
  Sys.sleep(1)
  html1 <- remote_driver$getPageSource()[[1]]
  Sys.sleep(1)
  ### encontros
  encontros <- html1 %>% 
    read_html() %>% 
    html_nodes(xpath = "//*[@id='divResultado1']/div/h2/text()") %>% 
    html_text()
  Sys.sleep(1)
  webElem <- remote_driver$findElements(using = 'css selector', "h2 > a")  
  for(j in 1:length(webElem)){
    clica(webElem[[j]])
    html <- remote_driver$getPageSource()[[1]]
    ## Nomes do GTs
    nome_gt <- html %>% 
      read_html() %>% 
      html_nodes(xpath = "//*[@id='divResultado1']/div/h1") %>% 
      html_text
    ## Título
    titulo <- html %>% 
      read_html() %>% 
      html_nodes(xpath =  "//label/a") %>% 
      html_text
    ## Autores
    autores <- html %>% 
      read_html() %>% 
      html_nodes(xpath =  "//p[2]/text()") %>% 
      html_text
    # pega links em pdf
    links <- html %>% 
      read_html() %>% 
      html_nodes(xpath = "//label/a") %>% 
      html_attr("href")
    ## (repetindo) Encontros
    encontros2 <- rep(encontros, length(links))
    ## (repetindo) Gts
    nome_gt2 <- rep(nome_gt, length(links))
    ## colando tudo em um data.frame vazio de nome "df" 
    df <- rbind(df, cbind(encontros2, nome_gt2, titulo, autores, links))}}

### Renomeando as colunas 
colnames(df)[1] <- "Edição"
colnames(df)[2] <- "Nome do GT"
colnames(df)[3] <- "Título"
colnames(df)[4] <- "Autores"
colnames(df)[5] <- "Links"


### Limpando um pouco a base de dados
edicao <- df$Edição
edicao <- noquote(edicao)
edicao <- gsub("Seja bem-vindo\\(a) aos anais do ", "", edicao)
edicao <- gsub(" - ISSN: 2236-4285", "", edicao)
df$Edição <- edicao


### Criando uma coluna com os anos **SEM WEBSCRAPING**

## Criando uma coluna com mesmo conteúdo das Edições
df$Ano <- df$Edição

## Substituindo as edições pelo ano correspondente  
  ano_vec <- df$Ano 
  ano_vec <- gsub("XXIX COMPÓS: UFMS/CAMPO GRANDE", "2020", ano_vec)
  ano_vec <- gsub("XXVIII COMPÓS: PUC/PORTO ALEGRE", "2019",ano_vec)
  ano_vec <- gsub("XXVII COMPÓS: BELO HORIZONTE/MG", "2018",ano_vec)
  ano_vec <- gsub("XXVI COMPÓS: SÃO PAULO/SP" , "2017",ano_vec)
  ano_vec <- gsub("XXV COMPÓS: GOIÂNIA/GO", "2016",ano_vec)
  ano_vec <- gsub("XXIV COMPOS: BRASÍLIA/DF" , "2015",ano_vec)
  ano_vec <- gsub("XXIII COMPOS: BELÉM/PA", "2014",ano_vec)
  ano_vec <- gsub("XXII COMPÓS: SALVADOR / BA", "2013",ano_vec)
  ano_vec <- gsub("XXI COMPÓS: JUIZ DE FORA / MG" , "2012",ano_vec)
  ano_vec <- gsub("XX COMPÓS: PORTO ALEGRE /RS", "2011",ano_vec)
  ano_vec <- gsub("XIX COMPÓS: RIO DE JANEIRO/RJ", "2010",ano_vec)
  ano_vec <- gsub("XVIII COMPÓS: BELO HORIZONTE/MG" , "2009",ano_vec)
  ano_vec <- gsub("XVII COMPÓS: SãO PAULO/SP" , "2008",ano_vec)
  ano_vec <- gsub("XVI COMPÓS: CURITIBA/PR" , "2007",ano_vec)
  ano_vec <- gsub("XV COMPÓS: BAURU/SP", "2006",ano_vec)
  ano_vec <- gsub("XIV COMPÓS: NITERóI/RJ", "2005",ano_vec)
  ano_vec <- gsub("XIII COMPÓS: SãO BERNARDO DO CAMPO/SP", "2004",ano_vec)
  ano_vec <- gsub("XII COMPÓS: RECIFE/PE", "2003",ano_vec)
  ano_vec <- gsub("XI COMPOS: RIO DE JANEIRO/RJ" , "2002",ano_vec)
  ano_vec <- gsub("X COMPOS: BRASíLIA/DF" , "2001",ano_vec)
  ano_vec <- gsub("IX COMPOS: PORTO ALEGRE/RS", "2000",ano_vec)

## Salvando na coluna Ano o resultado das substituições
df$Ano <- ano_vec

### Salvando a a base de dados coletada
write.csv(df, "./csv e RDS/compos.csv")
saveRDS(df, "./csv e RDS/compos.RDS")

### Se precisar abrir o RDS novamente sem precisar rodar o código

df <- readRDS("./csv e RDS/compos.RDS")

###########################################
#######     Download em Massa   ###########
###########################################
# Gerando links para download
links <- df$Links

# Escolhando a pasta de destinio dos arquivos
setwd("./PDFs/")

# Loop para download em massa de todos os links 
for (url in links){
  newName <- paste(format(Sys.time(), "%Y%m%d%H%M%S"), "-", basename(url), sep =" ")
  download.file(url, 
                destfile = newName,
                quiet = T,
                mode="wb")}

######################################
## Renomeando os arquivos em massa ###
#####################################

# Desabilite o comentário caso não queira ter que baixar tudo novamente 
#df <- readRDS("./csv e RDS/compos.RDS")

## Eliminando símbolos que o windows não aceita no nome do arquivo
## OBS: precisa ser melhorado para eliminar sobrescritpos
titulo <- df$'Título'
titulo <- gsub("\\:|\\?|\\/|*|ñ|\\(|\\)|\"|\n|[\u006E\u00B0\u00B2\u00B3\u00B9\u02AF\u0670\u0711\u2121\u213B\u2207\u29B5\uFC5B-\uFC5D\uFC63\uFC90\uFCD9\u2070\u2071\u2074-\u208E\u2090-\u209C\u0345\u0656\u17D2\u1D62-\u1D6A\u2A27\u2C7C]+/g
", "", titulo)

## Criando nomes os pdfs (ano - título.pdf)
ano <- df$Ano
nome_final <- paste0(ano, " - ", titulo)

### Renomenando em massa
# Novos nomes
oldNames<-list.files(".") #
newNames <- nome_final
for (i in 1:length(oldNames))file.rename(oldNames[i],newNames[i])
# Inserindo a extensão .pdf em todos
oldNames<-list.files(".") #
newNames<-paste(sep="",oldNames,".pdf")
for (i in 1:length(oldNames)) file.rename(oldNames[i],newNames[i])