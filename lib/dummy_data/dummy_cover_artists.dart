import 'package:flutter/material.dart';

import '../cover/cover_design.dart';
import '../main_page/writer_profile.dart';

/// Authentic Bangladeshi cover artists and designs list for offline testing
const List<WriterProfile> bangladeshiCoverArtists = [
  WriterProfile(
    name: 'Sabyasachi Hazra',
    accountId: 'sabyasachi-hazra',
    isCoverArtist: true,
    about:
        'Award-winning cover designer specializing in Bengali calligraphy, '
        'minimalist book art, and classic heritage typography.',
    designSpecialization: 'Calligraphy & Minimalist Typography',
    artStyle: 'Traditional Canvas & Digital Fusion',
    servicesOffered: 'Book Cover Design, Calligraphy, Layout Design',
    yearsOfExperience: '14 years',
    designTools: 'Adobe Illustrator, Photoshop, Custom Ink',
    workAvailability: 'Available for commissions',
    acceptsCustomRequests: 'Yes',
    pricingPackages: 'Premade: ৳1,500 | Custom Cover: ৳5,000',
    averageDeliveryTime: '3-5 days',
    revisionPolicy: 'Up to 3 revisions included',
    facebook: 'https://facebook.com/sabyasachi.hazra',
    instagram: 'https://instagram.com/sabyasachi_art',
    website: 'https://sabyasachidesigns.bd',
  ),
  WriterProfile(
    name: 'Dhruba Esh',
    accountId: 'dhruba-esh',
    isCoverArtist: true,
    about:
        'Master illustrator and designer behind thousands of legendary '
        'Bengali book covers, including famous Humayun Ahmed titles.',
    designSpecialization: 'Abstract Cover Art & Novel Illustrations',
    artStyle: 'Expressive Brushwork & Fine Line Illustration',
    servicesOffered: 'Full Jacket Cover Design, Novel Illustration',
    yearsOfExperience: '28 years',
    designTools: 'Gouache, Oil Paint, Digital Painting',
    workAvailability: 'Selected literary projects',
    acceptsCustomRequests: 'Yes',
    pricingPackages: 'Custom Design: ৳8,000',
    averageDeliveryTime: '5-7 days',
    revisionPolicy: '2 major concept revisions',
    facebook: 'https://facebook.com/dhruba.esh',
    website: 'https://dhrubaesh.com',
  ),
  WriterProfile(
    name: 'Kazi Anis',
    accountId: 'kazi-anis',
    isCoverArtist: true,
    about:
        'Modern digital concept artist creating vivid sci-fi, fantasy, and thriller covers '
        'for contemporary Bangladeshi authors.',
    designSpecialization: 'Digital Concept Art & Thriller Covers',
    artStyle: 'Cinematic & 3D Lighting Effects',
    servicesOffered: 'E-book Covers, Print Covers, Promotional Banners',
    yearsOfExperience: '8 years',
    designTools: 'Blender, Photoshop, Procreate',
    workAvailability: 'Open for all genre projects',
    acceptsCustomRequests: 'Yes',
    pricingPackages: 'Premade: ৳1,200 | Custom: ৳3,500',
    averageDeliveryTime: '2-4 days',
    revisionPolicy: 'Unlimited minor tweaks',
    instagram: 'https://instagram.com/kazianis_design',
  ),
];

const List<CoverDesign> bangladeshiCoverDesigns = [
  CoverDesign(
    title: 'Nondito Noroke',
    creator: 'Sabyasachi Hazra',
    color: Color(0xFF173B43),
    author: 'Humayun Ahmed',
    year: '2024',
  ),
  CoverDesign(
    title: 'Misir Ali - Mystery of Mind',
    creator: 'Dhruba Esh',
    color: Color(0xFFC89543),
    author: 'Humayun Ahmed',
    year: '2024',
  ),
  CoverDesign(
    title: 'Jochona O Jononir Golpo',
    creator: 'Sabyasachi Hazra',
    color: Color(0xFF8B263E),
    author: 'Humayun Ahmed',
    year: '2023',
  ),
  CoverDesign(
    title: 'Echoes of Padma',
    creator: 'Kazi Anis',
    color: Color(0xFF2C5E43),
    author: 'Selina Hossain',
    year: '2024',
  ),
  CoverDesign(
    title: 'Dhaka Monsoons & Memories',
    creator: 'Dhruba Esh',
    color: Color(0xFF3B4856),
    author: 'Tahmima Anam',
    year: '2023',
  ),
  CoverDesign(
    title: 'Agnivina - Special Edition',
    creator: 'Sabyasachi Hazra',
    color: Color(0xFFB84A28),
    author: 'Kazi Nazrul Islam',
    year: '2024',
  ),
];

const List<CoverDesign> bangladeshiCoverDrafts = [
  CoverDesign(
    title: 'Monsoon Letters (Draft 1)',
    creator: 'Sabyasachi Hazra',
    color: Color(0xFF3B5B66),
    author: 'Work in Progress',
    year: '2025',
    isDraft: true,
  ),
  CoverDesign(
    title: 'Shadows of Buriganga (Concept B)',
    creator: 'Kazi Anis',
    color: Color(0xFF4A3B56),
    author: 'Work in Progress',
    year: '2025',
    isDraft: true,
  ),
];
