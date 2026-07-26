import 'package:intl/intl.dart';
import '../../domain/models/mesh_packet.dart';

class FemaReportGenerator {

  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Generates a clean, human-readable Markdown FEMA ICS-213 report for native UI rendering.
  String generateIcs213Markdown(List<MeshPacket> incidents) {
    final filtered = incidents.where((p) => p.priority >= 2).toList();

    filtered.sort((a, b) {
      if (a.priority != b.priority) {
        return b.priority.compareTo(a.priority);
      }
      return b.timestamp.compareTo(a.timestamp);
    });

    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');

    final sb = StringBuffer();
    sb.writeln('# 📋 ICS 213: GENERAL MESSAGE FORM');
    sb.writeln('**FEMA Incident Command System — Emergency Log**\n');
    sb.writeln('---');
    sb.writeln('**1. Incident Name:** Mesh Network Local Area  ');
    sb.writeln('**2. To:** Emergency Command Center / Incident Commander  ');
    sb.writeln('**3. From:** RescueMesh Auto-Aggregator  ');
    sb.writeln('**4. Subject:** Prioritized Incident Log  ');
    sb.writeln('**5. Date:** ${DateFormat('yyyy-MM-dd').format(now)}  ');
    sb.writeln('**6. Time:** ${DateFormat('HH:mm').format(now)}  ');
    sb.writeln('----\n');

    sb.writeln('### 7. Message:');
    sb.writeln('The following critical and high-priority incidents have been aggregated via the off-grid BLE mesh network:\n');

    if (filtered.isEmpty) {
      sb.writeln('*No recent critical or high priority incident alerts recorded.*');
    } else {
      sb.writeln('| Time (Local) | Node ID | Priority | Category | Location | Message Payload |');
      sb.writeln('|---|---|---|---|---|---|');

      for (var packet in filtered) {
        final date = DateTime.fromMillisecondsSinceEpoch(packet.timestamp);
        final priorityStr = packet.priority == 3 ? '🔴 CRITICAL' : '🟠 HIGH';
        final typeStr = _getTypeString(packet.type);
        final locationMatch = RegExp(r'\[LAT: ([-\d.]+), LNG: ([-\d.]+)\]').firstMatch(packet.payload);
        final rawLocation = locationMatch != null ? '${locationMatch.group(1)}, ${locationMatch.group(2)}' : 'GPS Unavailable';

        final nodeIdShort = packet.originNodeId.length > 6 ? packet.originNodeId.substring(0, 6) : packet.originNodeId;

        sb.writeln('| ${formatter.format(date)} | `$nodeIdShort` | **$priorityStr** | $typeStr | $rawLocation | ${packet.payload} |');
      }
    }

    sb.writeln('\n---');
    sb.writeln('*Generated automatically by RescueMesh Field Tool • 100% Off-Grid Secure*');
    return sb.toString();
  }

  /// Generates a FEMA ICS-213 HTML report for copying or web printing.
  String generateIcs213Html(List<MeshPacket> incidents) {
    final filtered = incidents.where((p) => p.priority >= 2).toList();
    
    filtered.sort((a, b) {
      if (a.priority != b.priority) {
        return b.priority.compareTo(a.priority);
      }
      return b.timestamp.compareTo(a.timestamp);
    });

    final now = DateTime.now();
    final formatter = DateFormat('yyyy-MM-dd HH:mm:ss');
    
    StringBuffer rows = StringBuffer();
    for (var packet in filtered) {
      final date = DateTime.fromMillisecondsSinceEpoch(packet.timestamp);
      final priorityStr = packet.priority == 3 ? 'CRITICAL' : 'HIGH';
      final typeStr = _getTypeString(packet.type);
      final locationMatch = RegExp(r'\[LAT: ([-\d.]+), LNG: ([-\d.]+)\]').firstMatch(packet.payload);
      final rawLocation = locationMatch != null ? '${locationMatch.group(1)}, ${locationMatch.group(2)}' : 'Unknown';
      
      final escapedNodeId = _escapeHtml(packet.originNodeId);
      final escapedLocation = _escapeHtml(rawLocation);
      final escapedPayload = _escapeHtml(packet.payload);

      rows.writeln('''
        <tr>
          <td>${formatter.format(date)}</td>
          <td>${escapedNodeId.length > 6 ? escapedNodeId.substring(0, 6) : escapedNodeId}...</td>
          <td class="${priorityStr.toLowerCase()}">$priorityStr</td>
          <td>$typeStr</td>
          <td>$escapedLocation</td>
          <td>$escapedPayload</td>
        </tr>
      ''');
    }

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>FEMA ICS-213 General Message - RescueMesh</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; color: #333; }
        h1 { text-align: center; border-bottom: 2px solid #333; padding-bottom: 10px; }
        .header-info { display: flex; justify-content: space-between; margin-bottom: 20px; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; margin-top: 20px; }
        th, td { border: 1px solid #000; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        .critical { color: #d32f2f; font-weight: bold; }
        .high { color: #f57c00; font-weight: bold; }
        .footer { margin-top: 30px; font-size: 0.9em; text-align: center; color: #666; }
    </style>
</head>
<body>
    <h1>ICS 213: GENERAL MESSAGE</h1>
    <div class="header-info">
        <div>1. Incident Name: Mesh Network Local Area</div>
        <div>2. To (Name and Position): Emergency Command Center</div>
    </div>
    <div class="header-info">
        <div>3. From (Name and Position): RescueMesh Auto-Aggregator</div>
        <div>4. Subject: Prioritized Incident Log</div>
    </div>
    <div class="header-info">
        <div>5. Date: ${DateFormat('yyyy-MM-dd').format(now)}</div>
        <div>6. Time: ${DateFormat('HH:mm').format(now)}</div>
    </div>
    
    <h3>7. Message:</h3>
    <p>The following critical and high priority incidents have been aggregated via the local BLE mesh network:</p>
    
    <table>
        <thead>
            <tr>
                <th>Time (Local)</th>
                <th>Node ID</th>
                <th>Priority</th>
                <th>Category</th>
                <th>Location</th>
                <th>Message Payload</th>
            </tr>
        </thead>
        <tbody>
            ${rows.toString()}
        </tbody>
    </table>
    
    <div class="footer">
        Generated by RescueMesh Field Tool.<br>
        Page 1 of 1
    </div>
</body>
</html>
''';
  }

  String _getTypeString(int type) {
    switch (type) {
      case 1: return 'SOS';
      case 2: return 'Report';
      case 3: return 'Missing';
      case 4: return 'Resource';
      default: return 'General';
    }
  }
}
