# case_study
Refresh token yapısı backend tarafında başarıyla uygulanmış ve token’lar veritabanında saklanacak şekilde yapılandırılmıştır. Ancak frontend entegrasyonu aşamasında yaşanan teknik sorunlar ve zaman kısıtı nedeniyle frontend bağlantısı tamamlanamamıştır. Bu nedenle proje, backend servisleri odaklı olarak teslim edilmiştir.

Frontend tarafında API Base URL manuel olarak IP bazlı tanımlanmıştır. Bu yapı geçici bir çözümdür ve production ortamlar için environment variable tabanlı bir yapı ile güncellenmesi gerekmektedir. 

Uygulama Kubernetes ortamında Minikube kullanılarak çalıştırılmıştır. Servise erişim terminal üzerinden minikube service urun-takip-service komutu ile sağlanmaktadır. İlgili komut çalıştırıldığında uygulama otomatik olarak IP bazlı erişime açılmaktadır. API uç noktaları Postman aracılığıyla test edilebilir durumdadır.

Bu projede kubectl, FastAPI servisinin ve PostgreSQL veritabanının Kubernetes ortamında yönetilmesi, servislerin ayağa kaldırılması ve çalışma durumlarının kontrol edilmesi amacıyla kullanılmıştır.

Frontend entegrasyonu için gerekli altyapı backend tarafında hazır durumdadır.
