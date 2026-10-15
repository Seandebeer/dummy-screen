import '../models.dart';

/// Flight boards keep kind `flight`. The place they stand in is [OsSettings.face].
String transportMode(String face) {
  return switch (face) {
    'train' || 'bus' || 'ferry' => face,
    _ => 'flight',
  };
}

String transportHeading(String mode, String heading) {
  return switch (heading) {
    'none' => '',
    'arrivals' => 'Arrivals',
    _ => transportMode(mode) == 'ferry' ? 'Sailings' : 'Departures',
  };
}

const kTrainColumns = [
  'TIME',
  'DESTINATION',
  'OPERATOR',
  'TRAIN',
  'PLATFORM',
  'STATUS',
  'CAR',
];

const kBusColumns = [
  'TIME',
  'DESTINATION',
  'OPERATOR',
  'SERVICE',
  'BAY',
  'STATUS',
  'STAND',
];

const kFerryColumns = [
  'TIME',
  'DESTINATION',
  'OPERATOR',
  'SAILING',
  'BERTH',
  'STATUS',
  'DECK',
];

List<String> transportColumns(String mode, String heading) {
  final base = switch (transportMode(mode)) {
    'train' => kTrainColumns,
    'bus' => kBusColumns,
    'ferry' => kFerryColumns,
    _ => heading == 'arrivals' ? kFlightArriveColumns : kFlightColumns,
  };
  final next = [...base];
  if (transportMode(mode) != 'flight') {
    next[1] = heading == 'arrivals' ? 'ORIGIN' : 'DESTINATION';
  }
  return next;
}

List<String> transportBoard(String mode, {required bool second}) {
  return switch (transportMode(mode)) {
    'train' => second ? kTrainBoardB : kTrainBoardA,
    'bus' => second ? kBusBoardB : kBusBoardA,
    'ferry' => second ? kFerryBoardB : kFerryBoardA,
    _ => second ? kFlightBoardB : kFlightBoardA,
  };
}

/// Switching place rewrites the glass: columns, heading, and both boards.
OsSettings applyTransport(OsSettings os, String mode) {
  final next = transportMode(mode);
  return os.copyWith(
    face: next,
    flightColumns: transportColumns(next, os.flightHeading),
    flightTitle: transportHeading(next, os.flightHeading),
    flightA: transportBoard(next, second: false),
    flightB: transportBoard(next, second: true),
  );
}

/// Real operator name, lower case, to a fictional name and its letter code.
(String, String)? genericCarrier(String name, String mode) {
  final table = switch (transportMode(mode)) {
    'train' => _trainGenerics,
    'bus' => _busGenerics,
    'ferry' => _ferryGenerics,
    _ => _flightGenerics,
  };
  return table[name.trim().toLowerCase()];
}

const _flightGenerics = <String, (String, String)>{
  'alitalia': ('Skyline', 'SL'),
  'lufthansa': ('Northwind', 'NW'),
  'swissair': ('Alpine', 'AP'),
  'singapore airlines': ('Pacific', 'PC'),
  'blue panorama': ('Horizon', 'HZ'),
  'brussels airlines': ('Capital', 'CP'),
  'british airways': ('Crown Air', 'CR'),
  'sas': ('Nordic', 'ND'),
  'emirates': ('Gulf', 'GF'),
  'south african': ('Southern', 'SO'),
  'united': ('Continental', 'CT'),
  'vueling': ('Sunwing', 'SW'),
  'norwegian': ('Fjord', 'FJ'),
  'air france': ('Republic', 'RP'),
  'delta': ('Atlas', 'AT'),
  'klm': ('Lowland', 'LL'),
  'iberia': ('Iberic', 'IB'),
  'ana': ('Eastern', 'EA'),
  'aer lingus': ('Shamrock', 'SH'),
  'egyptair': ('Nile', 'NL'),
  'tap': ('Atlantic', 'AC'),
  'austrian': ('Danube', 'DN'),
  'finnair': ('Aurora', 'AU'),
  'aegean': ('Island Air', 'IA'),
  'lot': ('Central', 'CL'),
  'wizz': ('Budget', 'BG'),
};

const _trainGenerics = <String, (String, String)>{
  'amtrak': ('National Rail', 'NR'),
  'eurostar': ('Channel Line', 'CL'),
  'sncf': ('Republic Rail', 'RR'),
  'deutsche bahn': ('North Rail', 'NO'),
  'trenitalia': ('Peninsula', 'PN'),
  'renfe': ('Iberic Rail', 'IR'),
  'avanti': ('West Coast', 'WC'),
  'via rail': ('Maple Line', 'ML'),
  'jr east': ('Eastern Rail', 'ER'),
  'sbb': ('Alpine Rail', 'AR'),
  'thalys': ('Lowland Rail', 'LR'),
  'caltrain': ('Bay Line', 'BL'),
  'lner': ('East Coast', 'EC'),
  'obb': ('Danube Rail', 'DR'),
  'ns': ('Delta Rail', 'DL'),
  'sj': ('Nordic Rail', 'NK'),
  'irish rail': ('Harbor Rail', 'HR'),
  'scotrail': ('Highland', 'HL'),
};

const _busGenerics = <String, (String, String)>{
  'greyhound': ('Coach Line', 'CL'),
  'flixbus': ('Green Coach', 'GC'),
  'megabus': ('City Coach', 'CC'),
  'national express': ('Silver Line', 'SV'),
  'trailways': ('Valley Coach', 'VC'),
  'boltbus': ('Rapid Coach', 'RC'),
  'peter pan': ('Harbor Coach', 'HC'),
  'stagecoach': ('County Bus', 'CB'),
  'first': ('Metro Bus', 'MT'),
  'arriva': ('Region Bus', 'RB'),
  'go-ahead': ('Harbor Bus', 'HB'),
  'translink': ('North Bus', 'NB'),
  'dublin bus': ('Capital Bus', 'CP'),
  'bus eireann': ('West Bus', 'WB'),
  'scottish citylink': ('Glen Bus', 'GB'),
  'eurolines': ('Continental', 'CT'),
  'alsa': ('Sun Coach', 'SC'),
};

const _ferryGenerics = <String, (String, String)>{
  'irish ferries': ('Harbor Line', 'HL'),
  'p&o': ('Channel Ferry', 'CF'),
  'viking line': ('North Sea', 'NS'),
  'tallink': ('Baltic Line', 'BL'),
  'stena': ('Strait Line', 'SL'),
  'dfds': ('Coast Line', 'CL'),
  'grimaldi': ('Mediterranean', 'MD'),
  'tirrenia': ('Island Line', 'IL'),
  'color line': ('Fjord Line', 'FL'),
  'brittany ferries': ('West Channel', 'WC'),
  'balearia': ('Sun Ferry', 'SF'),
  'moby': ('Gulf Line', 'GL'),
  'finnlines': ('Aurora Line', 'AU'),
  'trasmediterranea': ('Southern Sea', 'SS'),
};

const kTrainBoardA = [
  '06:12\u001fLONDON EUSTON\u001fAmtrak\u001fAT 1402\u001f4\u001fON TIME\u001fA',
  '06:28\u001fPARIS GARE DE LYON\u001fEurostar\u001fES 9014\u001f7\u001fDELAYED\u001fB',
  '06:41\u001fLYON\u001fSNCF\u001fSN 6621\u001f2\u001fON TIME\u001fC',
  '07:05\u001fBERLIN HBF\u001fDeutsche Bahn\u001fDB 318\u001f9\u001fBOARDING\u001fD',
  '07:18\u001fMILAN CENTRALE\u001fTrenitalia\u001fTI 2044\u001f1\u001fON TIME\u001fA',
  '07:33\u001fMADRID ATOCHA\u001fRenfe\u001fRF 5510\u001f6\u001fON TIME\u001fB',
  '07:50\u001fGLASGOW\u001fAvanti\u001fAV 088\u001f3\u001fDELAYED\u001fC',
  '08:05\u001fTORONTO\u001fVIA Rail\u001fVR 41\u001f8\u001fON TIME\u001fD',
  '08:22\u001fTOKYO\u001fJR East\u001fJE 12\u001f5\u001fON TIME\u001fA',
  '08:40\u001fZURICH\u001fSBB\u001fSB 770\u001f2\u001fCANCELLED\u001fB',
  '08:55\u001fBRUSSELS\u001fThalys\u001fTH 9341\u001f11\u001fON TIME\u001fC',
  '09:10\u001fSAN JOSE\u001fCaltrain\u001fCT 218\u001f4\u001fON TIME\u001fD',
  '09:28\u001fEDINBURGH\u001fLNER\u001fLN 162\u001f6\u001fBOARDING\u001fA',
  '09:45\u001fVIENNA\u001fOBB\u001fOB 430\u001f1\u001fON TIME\u001fB',
  '10:02\u001fAMSTERDAM\u001fNS\u001fNS 2840\u001f9\u001fON TIME\u001fC',
  '10:20\u001fSTOCKHOLM\u001fSJ\u001fSJ 515\u001f3\u001fDELAYED\u001fD',
  '10:38\u001fDUBLIN\u001fIrish Rail\u001fIR 77\u001f7\u001fON TIME\u001fA',
  '11:05\u001fINVERNESS\u001fScotRail\u001fSR 19\u001f2\u001fCANCELLED\u001fB',
];

const kTrainBoardB = [
  '06:20\u001fBIRMINGHAM\u001fAvanti\u001fAV 104\u001f3\u001fARRIVED\u001fA',
  '06:36\u001fLILLE\u001fEurostar\u001fES 9102\u001f8\u001fON TIME\u001fB',
  '06:52\u001fMARSEILLE\u001fSNCF\u001fSN 6104\u001f1\u001fON TIME\u001fC',
  '07:10\u001fHAMBURG\u001fDeutsche Bahn\u001fDB 802\u001f6\u001fDELAYED\u001fD',
  '07:24\u001fROME TERMINI\u001fTrenitalia\u001fTI 1880\u001f2\u001fON TIME\u001fA',
  '07:41\u001fBARCELONA SANTS\u001fRenfe\u001fRF 2201\u001f5\u001fBOARDING\u001fB',
  '08:00\u001fMANCHESTER\u001fLNER\u001fLN 044\u001f9\u001fON TIME\u001fC',
  '08:15\u001fMONTREAL\u001fVIA Rail\u001fVR 62\u001f4\u001fON TIME\u001fD',
  '08:33\u001fOSAKA\u001fJR East\u001fJE 28\u001f7\u001fON TIME\u001fA',
  '08:48\u001fGENEVA\u001fSBB\u001fSB 512\u001f3\u001fCANCELLED\u001fB',
  '09:05\u001fCOLOGNE\u001fThalys\u001fTH 9410\u001f10\u001fON TIME\u001fC',
  '09:20\u001fPALO ALTO\u001fCaltrain\u001fCT 305\u001f2\u001fON TIME\u001fD',
  '09:38\u001fYORK\u001fLNER\u001fLN 210\u001f6\u001fON TIME\u001fA',
  '09:55\u001fSALZBURG\u001fOBB\u001fOB 118\u001f1\u001fDELAYED\u001fB',
  '10:12\u001fROTTERDAM\u001fNS\u001fNS 1411\u001f8\u001fON TIME\u001fC',
  '10:30\u001fGOTHENBURG\u001fSJ\u001fSJ 440\u001f5\u001fON TIME\u001fD',
  '10:48\u001fCORK\u001fIrish Rail\u001fIR 21\u001f4\u001fARRIVED\u001fA',
  '11:15\u001fABERDEEN\u001fScotRail\u001fSR 33\u001f2\u001fON TIME\u001fB',
];

const kBusBoardA = [
  '07:00\u001fBOSTON\u001fGreyhound\u001fGH 410\u001f3\u001fON TIME\u001fA',
  '07:15\u001fBERLIN ZOB\u001fFlixBus\u001fFB 882\u001f1\u001fDELAYED\u001fB',
  '07:30\u001fCHICAGO\u001fMegabus\u001fMB 125\u001f5\u001fON TIME\u001fC',
  '07:45\u001fLONDON VICTORIA\u001fNational Express\u001fNX 440\u001f2\u001fON TIME\u001fA',
  '08:00\u001fNEW YORK\u001fTrailways\u001fTW 66\u001f4\u001fBOARDING\u001fB',
  '08:20\u001fWASHINGTON\u001fBoltBus\u001fBB 19\u001f6\u001fON TIME\u001fC',
  '08:35\u001fPHILADELPHIA\u001fPeter Pan\u001fPP 302\u001f1\u001fON TIME\u001fA',
  '08:50\u001fMANCHESTER\u001fStagecoach\u001fSC 88\u001f7\u001fDELAYED\u001fB',
  '09:05\u001fLEEDS\u001fFirst\u001fFB 12\u001f3\u001fON TIME\u001fC',
  '09:20\u001fLIVERPOOL\u001fArriva\u001fAR 54\u001f8\u001fON TIME\u001fA',
  '09:40\u001fBRIGHTON\u001fGo-Ahead\u001fGA 9\u001f2\u001fCANCELLED\u001fB',
  '10:00\u001fBELFAST\u001fTranslink\u001fTL 210\u001f5\u001fON TIME\u001fC',
  '10:15\u001fDUBLIN\u001fDublin Bus\u001fDB 46A\u001f1\u001fON TIME\u001fA',
  '10:35\u001fGALWAY\u001fBus Eireann\u001fBE 20\u001f4\u001fON TIME\u001fB',
  '10:55\u001fGLASGOW\u001fScottish Citylink\u001fSC 916\u001f6\u001fDELAYED\u001fC',
  '11:10\u001fPARIS\u001fEurolines\u001fEL 33\u001f2\u001fON TIME\u001fA',
  '11:30\u001fMADRID\u001fAlsa\u001fAL 701\u001f8\u001fBOARDING\u001fB',
  '11:50\u001fBRISTOL\u001fNational Express\u001fNX 318\u001f3\u001fCANCELLED\u001fC',
];

const kBusBoardB = [
  '07:10\u001fBALTIMORE\u001fGreyhound\u001fGH 218\u001f2\u001fARRIVED\u001fA',
  '07:25\u001fPRAGUE\u001fFlixBus\u001fFB 104\u001f4\u001fON TIME\u001fB',
  '07:40\u001fDETROIT\u001fMegabus\u001fMB 77\u001f1\u001fON TIME\u001fC',
  '07:55\u001fOXFORD\u001fNational Express\u001fNX 202\u001f6\u001fDELAYED\u001fA',
  '08:10\u001fALBANY\u001fTrailways\u001fTW 14\u001f3\u001fON TIME\u001fB',
  '08:28\u001fBALTIMORE\u001fBoltBus\u001fBB 8\u001f5\u001fON TIME\u001fC',
  '08:42\u001fNEWARK\u001fPeter Pan\u001fPP 110\u001f2\u001fBOARDING\u001fA',
  '09:00\u001fSHEFFIELD\u001fStagecoach\u001fSC 41\u001f7\u001fON TIME\u001fB',
  '09:15\u001fYORK\u001fFirst\u001fFB 6\u001f4\u001fON TIME\u001fC',
  '09:32\u001fCHESTER\u001fArriva\u001fAR 19\u001f1\u001fCANCELLED\u001fA',
  '09:50\u001fPORTSMOUTH\u001fGo-Ahead\u001fGA 22\u001f8\u001fON TIME\u001fB',
  '10:08\u001fDERRY\u001fTranslink\u001fTL 88\u001f3\u001fON TIME\u001fC',
  '10:22\u001fCORK CITY\u001fDublin Bus\u001fDB 12\u001f5\u001fDELAYED\u001fA',
  '10:44\u001fLIMERICK\u001fBus Eireann\u001fBE 51\u001f2\u001fON TIME\u001fB',
  '11:02\u001fEDINBURGH\u001fScottish Citylink\u001fSC 900\u001f6\u001fON TIME\u001fC',
  '11:18\u001fLYON\u001fEurolines\u001fEL 40\u001f4\u001fARRIVED\u001fA',
  '11:36\u001fSEVILLE\u001fAlsa\u001fAL 330\u001f1\u001fON TIME\u001fB',
  '11:58\u001fCARDIFF\u001fNational Express\u001fNX 509\u001f7\u001fON TIME\u001fC',
];

const kFerryBoardA = [
  '08:00\u001fDOVER\u001fIrish Ferries\u001fIF 410\u001f2\u001fON TIME\u001f1',
  '08:30\u001fCALAIS\u001fP&O\u001fPO 220\u001f4\u001fDELAYED\u001f2',
  '09:00\u001fHELSINKI\u001fViking Line\u001fVL 15\u001f1\u001fON TIME\u001f3',
  '09:30\u001fSTOCKHOLM\u001fTallink\u001fTL 88\u001f6\u001fON TIME\u001f1',
  '10:00\u001fHOLYHEAD\u001fStena\u001fST 302\u001f3\u001fBOARDING\u001f2',
  '10:30\u001fROTTERDAM\u001fDFDS\u001fDF 44\u001f5\u001fON TIME\u001f4',
  '11:00\u001fBARCELONA\u001fGrimaldi\u001fGR 710\u001f2\u001fON TIME\u001f1',
  '11:30\u001fNAPLES\u001fTirrenia\u001fTI 19\u001f7\u001fDELAYED\u001f2',
  '12:00\u001fOSLO\u001fColor Line\u001fCL 6\u001f1\u001fON TIME\u001f3',
  '12:30\u001fCORK\u001fBrittany Ferries\u001fBF 51\u001f8\u001fON TIME\u001f1',
  '13:00\u001fTANGIER\u001fBalearia\u001fBA 90\u001f4\u001fCANCELLED\u001f2',
  '13:30\u001fGENOA\u001fMoby\u001fMO 12\u001f3\u001fON TIME\u001f1',
  '14:00\u001fBELFAST\u001fStena\u001fST 118\u001f6\u001fON TIME\u001f4',
  '14:30\u001fDUNKIRK\u001fDFDS\u001fDF 77\u001f2\u001fON TIME\u001f2',
  '15:00\u001fTURKU\u001fFinnlines\u001fFL 3\u001f5\u001fBOARDING\u001f3',
  '15:30\u001fSANTANDER\u001fBrittany Ferries\u001fBF 204\u001f1\u001fON TIME\u001f1',
  '16:00\u001fPALMA\u001fTrasmediterranea\u001fTM 66\u001f7\u001fDELAYED\u001f2',
  '16:30\u001fFISHGUARD\u001fIrish Ferries\u001fIF 55\u001f3\u001fCANCELLED\u001f1',
];

const kFerryBoardB = [
  '08:15\u001fROSSLARE\u001fIrish Ferries\u001fIF 102\u001f1\u001fDOCKED\u001f2',
  '08:45\u001fDOVER\u001fP&O\u001fPO 118\u001f5\u001fON TIME\u001f1',
  '09:15\u001fTALLINN\u001fViking Line\u001fVL 22\u001f2\u001fON TIME\u001f3',
  '09:45\u001fHELSINKI\u001fTallink\u001fTL 40\u001f6\u001fDELAYED\u001f2',
  '10:15\u001fDUBLIN PORT\u001fStena\u001fST 210\u001f3\u001fON TIME\u001f1',
  '10:45\u001fNEWCASTLE\u001fDFDS\u001fDF 9\u001f4\u001fON TIME\u001f4',
  '11:15\u001fCIVITAVECCHIA\u001fGrimaldi\u001fGR 330\u001f1\u001fBOARDING\u001f2',
  '11:45\u001fPALERMO\u001fTirrenia\u001fTI 44\u001f7\u001fON TIME\u001f1',
  '12:15\u001fKIEL\u001fColor Line\u001fCL 18\u001f2\u001fON TIME\u001f3',
  '12:45\u001fROSCOFF\u001fBrittany Ferries\u001fBF 80\u001f8\u001fCANCELLED\u001f2',
  '13:15\u001fIBIZA\u001fBalearia\u001fBA 14\u001f5\u001fON TIME\u001f1',
  '13:45\u001fBASTIA\u001fMoby\u001fMO 27\u001f3\u001fON TIME\u001f4',
  '14:15\u001fCAIRNRYAN\u001fStena\u001fST 64\u001f6\u001fDOCKED\u001f1',
  '14:45\u001fDIEPPE\u001fDFDS\u001fDF 31\u001f2\u001fON TIME\u001f2',
  '15:15\u001fTRAVEMUNDE\u001fFinnlines\u001fFL 11\u001f4\u001fDELAYED\u001f3',
  '15:45\u001fPLYMOUTH\u001fBrittany Ferries\u001fBF 155\u001f1\u001fON TIME\u001f1',
  '16:15\u001fVALENCIA\u001fTrasmediterranea\u001fTM 20\u001f7\u001fON TIME\u001f2',
  '16:45\u001fPEMBROKE\u001fIrish Ferries\u001fIF 70\u001f3\u001fON TIME\u001f1',
];
