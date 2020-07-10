# Sistema Viário


| Tipo | Origem | Pasta/Arquivo |
| - | - | - |
| Sistema Viário | Logradouro | SIRGAS_SHP_logradouronbl |
| Sistema Viário | Geolog - Geocodificação de Logradouros |

| Transporte | Corredores de ônibus | SIRGAS_SHP_corredoronibus |
| Transporte | CPTM Estação | SIRGAS_SHP_estacaotrem |
|  | Logradouro |
| Geolog | Geocodificação de Logradouros |
|  | Transporte -  |

# Conversão X, Y para Lat, Lng

http://www.dpi.inpe.br/calcula/

- Sua coordenada está em: **UTM (metros)**
- Selecione o Datum de entrada: **SIRGAS2000**
- Parâmetros de Projeção de entrada
  - Selecione Zona UTM: **Z 23 (o 45 00 00)**
  - Selecione o Datum de saída: **SIRGAS2000**

Teste:

- Entrada: `x` = 330270, `y` = 7397366
- Saída: `lat` = 23°31'30.4"S, `lng` = 46°39'45.2"W
- https://www.google.com.br/maps/place/23°31'30.4"S+46°39'45.2"W



