import '../main_page/writer_profile.dart';

/// Default Bangladeshi writer profile for current user (offline testing)
final WriterProfile defaultBangladeshiCurrentUser = WriterProfile(
  name: 'Amina Rahman',
  accountId: 'amina.rahman@novelly.bd',
  about:
      'Contemporary Bangladeshi author & book designer from Dhaka. '
      'Passionate about rain-soaked Dhaka nostalgia, literary fiction, and book jacket artwork.',
  goodreads: 'https://goodreads.com/aminarahman',
  facebook: 'https://facebook.com/amina.rahman.writer',
  instagram: 'https://instagram.com/amina_reads',
  website: 'https://aminarahman.bd',
  isWriter: true,
  isPublisher: true,
  isCoverArtist: true,
  followerIds: List.generate(3420, (i) => 'follower-$i'),
  publishers: const [
    'Prothoma Prokashan',
    'Batighar Prokashani',
    'Anyaprokash',
  ],
  books: const [
    WriterBook(
      title: 'The Silent Ink',
      rating: 4.8,
      reviews: [
        WriterBookReview(
          reviewerName: 'Rafiq Hasan',
          rating: 5.0,
          body: 'A deeply moving story that captures the soul of Old Dhaka.',
        ),
        WriterBookReview(
          reviewerName: 'Nadia Islam',
          rating: 4.5,
          body: 'Beautiful prose and compelling character development.',
        ),
      ],
    ),
    WriterBook(
      title: 'Whispers of the Valley',
      rating: 4.6,
      reviews: [
        WriterBookReview(
          reviewerName: 'Arman Chowdhury',
          rating: 4.7,
          body: 'Evocative storytelling and exquisite imagery.',
        ),
      ],
    ),
    WriterBook(
      title: 'Rain over Ramna',
      rating: 4.9,
      reviews: [
        WriterBookReview(
          reviewerName: 'Leena Akter',
          rating: 5.0,
          body: 'Captures the magic of monsoon in Dhaka like no other book.',
        ),
      ],
    ),
  ],
);
