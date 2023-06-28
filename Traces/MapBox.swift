//  MapBoxMapView.swift
//  Traces
//
//  Created by Bryce on 6/13/23.


import SwiftUI
import Supabase
import MapboxMaps

struct MapBox: View {

    @State var center = CLLocationCoordinate2D(latitude: 37.789467, longitude: -122.416772)
    var interactable: Bool = false
    @State var annotations: [CLLocationCoordinate2D] = []
    @StateObject var themeManager: ThemeManager = ThemeManager.shared
    @ObservedObject var supabaseManager: SupabaseManager = SupabaseManager.shared
    
    var body: some View {
        MapBoxViewConverter(center: center, interactable: interactable, style: StyleURI(rawValue: themeManager.theme.mapStyle)!, annotations: $annotations)
            .task {
                await supabaseManager.reloadTraces()
            }
            .onAppear {
                updateAnnotations()
            }
    }
    
    func updateAnnotations() {
        annotations = supabaseManager.traces.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }
}

struct MapBoxViewConverter: UIViewControllerRepresentable {
    let center: CLLocationCoordinate2D
    let interactable: Bool
    @State var style: StyleURI
    @Binding var annotations: [CLLocationCoordinate2D]
    @ObservedObject var themeManager: ThemeManager = ThemeManager.shared
    
    func makeUIViewController(context: Context) -> MapViewController {
        return MapViewController(center: center, style: style, annotations: $annotations, themeManager: themeManager, interactable: interactable)
    }
    
    func updateUIViewController(_ uiViewController: MapViewController, context: Context) {
        uiViewController.updateAnnotations(annotations: annotations)
        uiViewController.updateStyle(StyleURI(rawValue: themeManager.theme.mapStyle)!)
    }
}

class MapViewController: UIViewController {
    let center: CLLocationCoordinate2D
    let style: StyleURI
    let zoom: Double
    @Binding var annotations: [CLLocationCoordinate2D]
    let themeManager: ThemeManager
    var interactable: Bool
    internal var mapView: MapView!
    
    public var lightSnapshotter: Snapshotter!
    public var darkSnapshotter: Snapshotter!
    public var snapshotView: UIImageView!
    private var snapshotting = false
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(frame: view.safeAreaLayoutGuide.layoutFrame)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.alignment = .fill
        stackView.spacing = 12.0
        return stackView
    }()

    
    init(center: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 40.83647410051574, longitude: 14.30582273457794),
         style: StyleURI = StyleURI(rawValue: "mapbox://styles/atxls/cliuqmp8400kv01pw57wxga7l")!,
         zoom: Double = 10,
         annotations: Binding<[CLLocationCoordinate2D]>,
         themeManager: ThemeManager,
         interactable: Bool = false
    ) {
        self.center = center
        self.style = style
        self.zoom = zoom
        self._annotations = annotations
        self.themeManager = themeManager
        self.interactable = interactable
        super.init(nibName: nil, bundle: nil)

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()

        let resourceOptions = ResourceOptions(accessToken: mapBoxAccessToken)
        let cameraOptions = CameraOptions(center: center, zoom: zoom)
        let myMapInitOptions = MapInitOptions(resourceOptions: resourceOptions, cameraOptions: cameraOptions, styleURI: style)
        
        mapView = MapView(frame: view.bounds, mapInitOptions: myMapInitOptions)
        updateAnnotations(annotations: annotations)
        
        mapView.ornaments.options = ornamentOptions()
        
        if !interactable {
            mapView.gestures.options = disabledGestureOptions
        }
        
        mapView.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]
        self.view.addSubview(mapView)
        
    }
    
    func updateAnnotations(annotations: [CLLocationCoordinate2D]) {
        var circleAnnotations: [CircleAnnotation] = []
        
        for annotation in annotations {
            let circleAnnotation = CircleAnnotation(centerCoordinate: annotation)
            circleAnnotations.append(circleAnnotation)
        }
        
        let circleAnnotationManager = mapView.annotations.makeCircleAnnotationManager()
        circleAnnotationManager.annotations = circleAnnotations
    }
    
    func updateStyle(_ style: StyleURI) {
        mapView.mapboxMap.loadStyleURI(style)
    }
    
    
    private func initializeSnapshotter() {

        let size = CGSize(
            width: view.safeAreaLayoutGuide.layoutFrame.width,
            height: (view.safeAreaLayoutGuide.layoutFrame.height - stackView.spacing) / 2)
        let options = MapSnapshotOptions(
            size: size,
            pixelRatio: UIScreen.main.scale,
            resourceOptions: ResourceOptionsManager.default.resourceOptions,
            showsLogo: false,
            showsAttribution: false
        )
        
        lightSnapshotter = Snapshotter(options: options)
        lightSnapshotter.style.uri = StyleURI(rawValue: themeManager.theme.mapStyle)
        darkSnapshotter = Snapshotter(options: options)
        darkSnapshotter.style.uri = StyleURI(rawValue: themeManager.theme.mapStyle)

        mapView.mapboxMap.onEvery(event: .mapIdle) { [weak self] _ in
            guard let self = self, !self.snapshotting else {
                return
            }
            
            let snapshotterCameraOptions = CameraOptions(cameraState: self.mapView.cameraState)
            self.lightSnapshotter.setCamera(to: snapshotterCameraOptions)
            self.startSnapshot(lightSnapshotter)
        }
    }
    
    public func startSnapshot(_ snapshotter: Snapshotter) {
        snapshotting = true
        snapshotter.start(overlayHandler: nil) { ( result ) in
            switch result {
            case .success(let image):
                self.snapshotView.image = image
            case .failure(let error):
                print("Error generating snapshot: \(error)")
            }
            self.snapshotting = false
        }
    }
    
    private let disabledGestureOptions = GestureOptions(panEnabled: false, pinchEnabled: false, rotateEnabled: false, simultaneousRotateAndPinchZoomEnabled: false, pinchZoomEnabled: false, pinchPanEnabled: false, pitchEnabled: false, doubleTapToZoomInEnabled: false, doubleTouchToZoomOutEnabled: false, quickZoomEnabled: false)
    
    let ornamentOptions = {
        let scaleBarOptions = ScaleBarViewOptions(margins: CGPoint(x: 10, y: 60))
        let logoOptions = LogoViewOptions(margins: CGPoint(x: 10, y: 110))
        let attributionOptions = AttributionButtonOptions(margins: CGPoint(x: 0, y: 106))
        return OrnamentOptions(scaleBar: scaleBarOptions, logo: logoOptions, attributionButton: attributionOptions)
    }
}


// use snapshotter when traces are initialized, different ones for each theme.  Snapshot all maps so they dont reload
