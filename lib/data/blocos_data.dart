import '../models/bloco_event.dart';

class BlocosData {
  static List<BlocoEvent> getBlocos() {
    return [
      BlocoEvent(
        id: '1',
        name: 'Axe e Micareta com Asa de Banana',
        dateTime: DateTime(2026, 1, 16, 18, 0),
        description:
            'Energia, nostalgia e animacao dos grandes carnavais e micaretas dos anos 90 e 2000! '
            'A banda Asa de Banana traz os maiores hits do axe music em uma noite inesquecivel. '
            'Venha reviver os classicos que marcaram geracao!',
        address: 'Rua Mucuri, 325 - Amadoria',
        neighborhood: 'Floresta',
        ticketPrice: 'A partir de R\$ 20',
        ticketUrl: 'https://www.sympla.com.br',
        latitude: -19.9191,
        longitude: -43.9386,
        tags: ['Axe', 'Micareta', '90s', '2000s'],
      ),
      BlocoEvent(
        id: '2',
        name: 'Ensaios da Eazy',
        dateTime: DateTime(2026, 1, 16, 23, 0),
        description:
            'Os ensaios mais animados de BH estao de volta! '
            'Eazy traz a energia contagiante do funk e pagode para esquentar o pre-carnaval. '
            'Vista sua fantasia e venha sambar!',
        address: 'Rua Curitiba, 1200',
        neighborhood: 'Barro Preto',
        ticketPrice: 'A partir de R\$ 30',
        latitude: -19.9285,
        longitude: -43.9442,
        tags: ['Funk', 'Pagode', 'Ensaio'],
      ),
      BlocoEvent(
        id: '3',
        name: 'Ensaio de Carnaval na Arena',
        dateTime: DateTime(2026, 1, 17, 11, 0),
        description:
            'Comece o sabado com muito samba e alegria! '
            'Ensaio aberto com bateria ao vivo, passistas e muita animacao. '
            'Traga a familia toda para curtir o clima de carnaval!',
        address: 'Av. dos Andradas, 3000',
        neighborhood: 'Santa Efigenia',
        ticketPrice: 'Entrada Gratuita',
        latitude: -19.9167,
        longitude: -43.9253,
        tags: ['Samba', 'Familia', 'Gratuito'],
      ),
      BlocoEvent(
        id: '4',
        name: 'Encontro de Blocos',
        dateTime: DateTime(2026, 1, 17, 13, 0),
        description:
            'O maior encontro de blocos de BH! '
            'Diversos blocos se reunem para um mega desfile pelas ruas do bairro. '
            'Traga seu abada e venha fazer parte dessa festa!',
        address: 'Praca do Papa',
        neighborhood: 'Dom Cabral',
        ticketPrice: 'Entrada Gratuita',
        latitude: -19.9042,
        longitude: -43.9578,
        tags: ['Blocos', 'Desfile', 'Gratuito'],
      ),
      BlocoEvent(
        id: '5',
        name: 'Pre-Carnaval de BH',
        dateTime: DateTime(2026, 1, 17, 14, 0),
        description:
            'O tradicional pre-carnaval de Belo Horizonte! '
            'Atracao principal com grandes nomes da musica brasileira. '
            'Venha curtir ao ar livre com muita cerveja gelada e axe!',
        address: 'Expominas',
        neighborhood: 'Gameleira',
        ticketPrice: 'A partir de R\$ 50',
        latitude: -19.9094,
        longitude: -44.0144,
        tags: ['Show', 'Axe', 'Cerveja'],
      ),
      BlocoEvent(
        id: '6',
        name: 'Bloco Duro de Matar',
        dateTime: DateTime(2026, 1, 18, 16, 0),
        description:
            'O bloco mais animado da cidade esta de volta! '
            'Com muito rock, pop e marchinhas de carnaval, '
            'o Duro de Matar promete agitar as ruas de BH. '
            'Fantasia obrigatoria!',
        address: 'Rua da Bahia, 1400',
        neighborhood: 'Centro',
        ticketPrice: 'A partir de R\$ 25',
        latitude: -19.9197,
        longitude: -43.9378,
        tags: ['Rock', 'Pop', 'Marchinhas'],
      ),
      BlocoEvent(
        id: '7',
        name: 'Bloco Chama o Sindico',
        dateTime: DateTime(2026, 1, 18, 15, 0),
        description:
            'Prepare-se para o bloco mais zoeiro de BH! '
            'Com marchinhas, funk e muito humor, '
            'o Chama o Sindico vai fazer voce rir e dancar ao mesmo tempo!',
        address: 'Praca da Savassi',
        neighborhood: 'Savassi',
        ticketPrice: 'Entrada Gratuita',
        latitude: -19.9352,
        longitude: -43.9342,
        tags: ['Humor', 'Funk', 'Marchinhas', 'Gratuito'],
      ),
      BlocoEvent(
        id: '8',
        name: 'Bloco Tico Tico Serra Copo',
        dateTime: DateTime(2026, 1, 19, 10, 0),
        description:
            'Um dos blocos mais tradicionais de BH! '
            'Com mais de 20 anos de historia, o Tico Tico Serra Copo '
            'traz o verdadeiro espirito do carnaval de rua mineiro.',
        address: 'Av. Afonso Pena, 1500',
        neighborhood: 'Centro',
        ticketPrice: 'Entrada Gratuita',
        latitude: -19.9242,
        longitude: -43.9364,
        tags: ['Tradicional', 'Samba', 'Gratuito'],
      ),
      BlocoEvent(
        id: '9',
        name: 'Bloco do Beco',
        dateTime: DateTime(2026, 1, 19, 14, 0),
        description:
            'O Bloco do Beco transforma as ruas estreitas do centro '
            'em uma grande pista de danca! Venha curtir com a galera '
            'e sentir a energia do carnaval de perto.',
        address: 'Beco do Mingau',
        neighborhood: 'Lourdes',
        ticketPrice: 'A partir de R\$ 15',
        latitude: -19.9311,
        longitude: -43.9436,
        tags: ['Alternativo', 'Indie'],
      ),
      BlocoEvent(
        id: '10',
        name: 'Bloco da Praia da Estacao',
        dateTime: DateTime(2026, 1, 24, 16, 0),
        description:
            'A Praia da Estacao e o ponto de encontro mais famoso do carnaval de BH! '
            'Traga sua canga, seu biquini e venha curtir o "verao" mineiro '
            'ao som de muito samba e marchinhas.',
        address: 'Praca da Estacao',
        neighborhood: 'Centro',
        ticketPrice: 'Entrada Gratuita',
        latitude: -19.9189,
        longitude: -43.9386,
        tags: ['Praia', 'Samba', 'Tradicional', 'Gratuito'],
      ),
      BlocoEvent(
        id: '11',
        name: 'Bloco Coracao de Pe de Moleque',
        dateTime: DateTime(2026, 1, 25, 13, 0),
        description:
            'Com o coracao doce como pe de moleque, este bloco traz '
            'o melhor do sertanejo e do forro para as ruas de BH. '
            'Vista sua camisa xadrez e venha arrastar o pe!',
        address: 'Mercado Central',
        neighborhood: 'Centro',
        ticketPrice: 'A partir de R\$ 20',
        latitude: -19.9205,
        longitude: -43.9411,
        tags: ['Sertanejo', 'Forro'],
      ),
      BlocoEvent(
        id: '12',
        name: 'Bloco das Bruxas',
        dateTime: DateTime(2026, 1, 25, 18, 0),
        description:
            'O bloco mais mistico de BH! As bruxas invadem as ruas '
            'com muita musica eletronica e performances artisticas. '
            'Vista sua capa e traga sua vassoura!',
        address: 'Praca da Liberdade',
        neighborhood: 'Funcionarios',
        ticketPrice: 'A partir de R\$ 35',
        latitude: -19.9317,
        longitude: -43.9378,
        tags: ['Eletronica', 'Alternativo'],
      ),
    ];
  }
}
