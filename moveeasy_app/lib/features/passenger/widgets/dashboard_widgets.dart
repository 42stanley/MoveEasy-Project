import 'package:flutter/material.dart';

class QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subLabel;
  final VoidCallback? onTap;

  const QuickAction({
    super.key,
    required this.icon,
    required this.label,
    required this.subLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                child: Icon(icon, color: Colors.blue[700], size: 28),
              ),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Text(subLabel, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class QueueCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final int count;
  final String status;
  final Color color;

  const QueueCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.count,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Icon(Icons.trending_up, color: color, size: 20),
            ],
          ),
          Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
                    Text('~3 min wait', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RouteCard extends StatelessWidget {
  final String code;
  final String name;
  final String time;
  final String queueStatus;
  final Color color;

  const RouteCard({
    super.key,
    required this.code,
    required this.name,
    required this.time,
    required this.queueStatus,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
            child: Text(code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(time, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(4)),
            child: Text('Accessible', style: TextStyle(color: Colors.green[700], fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
