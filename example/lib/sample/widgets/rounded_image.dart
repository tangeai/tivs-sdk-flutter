part of 'rapid_kit_sample_widget.dart';

class RoundedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double borderRadius;

  const RoundedNetworkImage({
    super.key,
    required this.imageUrl,
    this.borderRadius = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) {
              return child;
            } else {
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                      : null,
                ),
              );
            }
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.blueGrey,
            );
          },
        ),
      ),
    );
  }
}
