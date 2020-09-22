import { Injectable } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Theatre } from './theatre.schema';
import { CreateDocumentDefinition, Model } from 'mongoose';

const seedTheatres: Omit<CreateDocumentDefinition<Theatre>, '_id'>[] = [
  {
    name: 'Galaxy - Đà Nẵng',
    address: 'Tầng 3, TTTM Coop Mart, 478 Điện Biên Phủ, Quận Thanh Khê, Đà Nẵng',
    location: {
      type: 'Point',
      coordinates: [108.1861624, 16.0666692],
    },
    phone_number: '02363739888',
    is_active: true,
    description: 'Thành lập hơn mười năm, Galaxy Cinema đã trở thành một thương hiệu nổi tiếng, được cả nước biết đến. Ngày 23/9/2016, hệ thống rạp phim hàng đầu đã cập bến Đà Nẵng, hứa hẹn đem đến cho các bạn trẻ bên bờ sông Hàn một địa điểm vui chơi mới mẻ.',
    email: null,
    opening_hours: '9:00 - 23:00',
    room_summary: '7 2D, 1 3D',
    rooms: [
      '2D 1',
      '2D 2',
      '2D 3',
      '2D 4',
      '2D 5',
      '2D 6',
      '2D 7',
      '3D',
    ]
  },
  {
    name: 'Starlight Đà Nẵng',
    address: 'T4-Tòa nhà Nguyễn Kim, 46 Điện Biên Phủ, ĐN',
    location: {
      type: 'Point',
      coordinates: [108.2052573, 16.0662866],
    },
    phone_number: '19001744',
    is_active: true,
    description: 'Quy mô 4 phòng chiếu phim hiện đại, sức chứa lên đến 688 ghế ngồi được thiết kế với phong cách hiện đại, đem lại cảm giác thoãi mái cho người xem.Ngoài ra phòng chiếu còn được trang bị hệ thống âm thanh Dolby 7.1 sống động, màn hình chiếu kĩ thuật 2D, 3D sắc nét đến từng phân đoạn.',
    email: null,
    opening_hours: '8:30 - 23:30',
    room_summary: '4 2D',
    rooms: [
      '2D 1',
      '2D 2',
      '2D 3',
      '2D 4',
    ]
  },
  {
    name: 'Lotte Cinema Đà Nẵng',
    address: 'Lotte Mart Đà Nẵng, Hải Châu, ĐN',
    location: {
      type: 'Point',
      coordinates: [108.2291364, 16.0347492],
    },
    phone_number: '02363679667',
    is_active: true,
    description: 'Rạp chiếu phim Lotte Cinema Đà Nẵng nằm trên tầng 5 và 6 của khu trung tâm mua sắm Lotte Mart, nằm trên đường 2 Tháng 9 bên cạnh dòng sông Hàn thơ mộng và khu thể thao Tiên Sơn. Đây là một trong những rạp chiếu phim hiện đại đẳng cấp quốc tế thuộc hệ thống rạp chiếu Lotte Cinema của Hàn Quốc',
    email: null,
    opening_hours: '8:00 - 24:00',
    room_summary: '4 2D',
    rooms: [
      '2D 1',
      '2D 2',
      '2D 3',
      '2D 4',
    ]
  }
];

@Injectable()
export class TheatresService {
  constructor(
      @InjectModel(Theatre.name) private readonly theatreModel: Model<Theatre>,
  ) {}

  async seed(): Promise<string | Theatre[]> {
    if (await this.theatreModel.estimatedDocumentCount().exec() > 0) {
      return 'Nice';
    }
    return await this.theatreModel.create(seedTheatres);
  }
}