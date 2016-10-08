//
//  AlgorithmViewController.swift
//  AlgoPlay
//
//  Created by Admin on 07.10.16.
//  Copyright © 2016 Vanoproduction. All rights reserved.
//

import UIKit

class AlgorithmViewController : UIViewController {
    
    let MAIN_COLOR:UIColor = UIColor(red: 7/255, green: 151/255, blue: 0, alpha: 1.0)
    let BAR_COLOR:UIColor = UIColor(red: 239/255, green: 249/255, blue: 238/255, alpha: 1.0)
    let PRIM_SPEED:[Int] = [37,74,148]
    let POISSON_SPEED:[Int] = [2,4,8]
    let RANDOM_SPEED:[Int] = [70,140,280]
    let LAYER_ANIMATION_DURATION:CFTimeInterval = 0.15
    let INFO_VIEW_OPACITY:CGFloat = 0.85
    
    var current_speed = 1 // 0 - 0.5x , 1 - 1.0x , 2 - 2.0x
    var current_type = ""
    var in_progress = false
    var image_holder:UIImageView!
    var draw_zone:CGRect!
    var display_link:CADisplayLink!
    var current_job_pixel:JobPixel!
    var current_job_layer:JobLayer!
    var info_view:UIView!
    var info_label:UILabel!
    var draw_layer:CALayer!
    var toolbar:UIToolbar!
    var info_shown = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.edgesForExtendedLayout = UIRectEdge.None
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "startTapped:"))
        navigationItem.setRightBarButtonItem(UIBarButtonItem(image: UIImage(named: "info")!, style: .Plain, target: self, action: "infoButtonPressed:"), animated: false)
        toolbar = UIToolbar(frame: CGRect(x: 0, y: view.bounds.height - 45, width: view.bounds.width, height: 45))
        let speed_button = UIBarButtonItem(title: "Speed 1x", style: .Plain, target: self, action: "speedButtonPressed:")
        let retry_button = UIBarButtonItem(image: UIImage(named: "retry_icon")!, style: .Plain, target: self, action: "retryButtonPressed:")
        let space = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: self, action: "dd:")
        toolbar.setItems([speed_button,space,retry_button], animated: false)
        toolbar.tintColor = MAIN_COLOR
        toolbar.barTintColor = BAR_COLOR
        view.addSubview(toolbar)
        let navBarHeight = navigationController!.navigationBar.frame.maxY
        draw_zone = CGRectMake(0, navBarHeight, view.bounds.width, view.bounds.height - navBarHeight - 45)
        image_holder = UIImageView(frame: CGRect(x: 0, y: draw_zone.minY, width: view.bounds.width, height: draw_zone.height))
        display_link = CADisplayLink(target: self, selector: "iteration:")
        display_link.paused = true
        display_link.frameInterval = 1
        display_link.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
        draw_layer = CALayer()
        draw_layer.frame = image_holder.frame
        view.layer.addSublayer(draw_layer)
        info_view = UIView(frame: image_holder.frame)
        info_view.backgroundColor = UIColor.whiteColor()
        info_view.alpha = 0.0
        info_label = UILabel(frame: CGRect(x: 5, y: 4, width: view.bounds.width - 5 - 5, height: 50))
        info_label.numberOfLines = 0
        info_label.font = UIFont.systemFontOfSize(13)
        info_view.addSubview(info_label)
        view.addSubview(image_holder)
        view.addSubview(info_view)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        var info_title = ""
        switch current_type {
        case "rand" :
            info_title = "This maze generating algorithm creates random spanning tree. Starting from the point specified, it maintains an array of all possible directions the maze can be potentially extended to. Then at each iteration random direction is selected and consequently drawn on the screen. Every pixel on the screen acts as node in a spanning tree. We keep building our maze until all nodes are checked and used.\nEach pixel is encoded with HSB model. The same coloring rules as Prim's tree has are applied here."
        case "prim" :
            info_title = "Prim's tree generating algorithm creates minimum spanning tree. Tree has to posess some nodes, so in our case each pixel on the screen acts as a separate node. Starting with the point specified, the algorithm keeps array of all possible directions where our maze can be extended. At each iteration a direction with minimum weight is extracted and used. Every possible direction has a weight assigned randomly.\nA minHeap structure was implemented to keep finding minimum weight as fast as possible. It allowed me to maintain O(log n) complexity.\nSo that to make this process more descriptive, each new node-pixel is filled with color. Color is created with hue-saturation-brightness model, where saturation and brightness remain constant, while hue is getting incremented with each iteration. That enables us to observe an order in which maze is generated."
        case "poisson" :
            info_title = "Even points distribution has always been a real problem. But using Bridson's algorithm for Poisson's disc sampling we can achieve it. The algorithm keeps an array of so called active points. Specified starting point becomes the first active point. Then at each iteration random active point is selected and new points-candidates are generated. Those candidates should be placed in (r,2r) distance from the active point and must not be situated too close to any other already created point(distance < r). r there means predefined minimum distance between points, which can make whole picture look too condensed or too broad. When candidate which satisfies requirements is generated, it is appended to an active array, and next iteration begins. There is also a constant named POISSON_LIMIT. It describes amount of candidates each active point should generate before considering itself inactive and as a result removing itself from an active array. The bigger value for POISSON_LIMIT you specify, the more even points distribution you eventually get.\nTo avoid checking distance between new candidate and every single point already created, a square-shaped grid was implemented. It has a size of r*sqrt(2), which ensures each cell has only one point at a time. So you should only look at points situated in adjacent cells."
        default:
            break
        }
        info_label.text = info_title
        info_label.sizeToFit()
        welcome()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        in_progress = false
        display_link.paused = true
        image_holder.image = nil
        info_shown = false
        info_view.alpha = 0.0
        self.navigationItem.setRightBarButtonItem(UIBarButtonItem(image: UIImage(named: "info")!, style: .Plain, target: self, action: "infoButtonPressed:"), animated: false)
    }
    
    func welcome() {
        if !in_progress {
            display_link.paused = true
            image_holder.image = nil
            if let sublayers = draw_layer.sublayers {
                for sublayer in sublayers {
                    sublayer.removeFromSuperlayer()
                }
            }
            in_progress = false
            let alert = UIAlertController(title: "Touch somewhere", message: "This is going to be the starting point", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: {
                (act:UIAlertAction) in
                alert.dismissViewControllerAnimated(true, completion: nil)
            }))
            presentViewController(alert, animated: true, completion: nil)
        }
    }
    
    func prepareWithType(type:String) {
        current_type = type
        var title = ""
        switch type {
        case "rand" :
            title = "Random traversal"
        case "prim" :
            title = "Prim's tree"
        case "poisson" :
            title = "Poisson distribution"
        default:
            break
        }
        navigationItem.title = title
    }
    
    func startJobWithStartPoint(startPoint:CGPoint) {
        switch current_type {
        case "prim" :
            current_job_pixel = PrimJob(drawZone: draw_zone)
        case "rand" :
            current_job_pixel = RandomJob(drawZone: draw_zone)
        case "poisson" :
            current_job_layer = PoissonJob(drawLayer: draw_layer)
        default:
            break
        }
        if current_type == "prim" || current_type == "rand" {
            current_job_pixel.startPoint = startPoint
            current_job_pixel.startJob()
        }
        else {
            current_job_layer.startPoint = startPoint
            current_job_layer.startJob()
        }
        display_link.paused = false
    }
    
    func retryButtonPressed(sender:UIBarButtonItem) {
        in_progress = false
        welcome()
    }
    
    func speedButtonPressed(sender:UIBarButtonItem) {
        if current_speed == 2 {
            current_speed = 0
        }
        else if current_speed == 1 {
            current_speed = 2
        }
        else {
            current_speed = 1
        }
        let speed_title = current_speed == 0 ? "Speed 0.5x" : current_speed == 1 ? "Speed 1x" : "Speed 2x"
        toolbar.items![0] = UIBarButtonItem(title: speed_title, style: .Plain, target: self, action: "speedButtonPressed:")
    }
    
    
    func infoButtonPressed(sender:UIBarButtonItem) {
        UIView.animateWithDuration(0.55, animations: {
            self.info_view.alpha = self.info_shown ? 0.0 : self.INFO_VIEW_OPACITY
            }, completion: {
                (fin:Bool) in
                self.info_shown = !self.info_shown
                if self.info_shown {
                    self.navigationItem.setRightBarButtonItem(UIBarButtonItem(title: "Close", style: .Plain, target: self, action: "infoButtonPressed:"), animated: true)
                }
                else {
                    self.navigationItem.setRightBarButtonItem(UIBarButtonItem(image: UIImage(named: "info")!, style: .Plain, target: self, action: "infoButtonPressed:"), animated: true)
                }
        })
    }
    
    func startTapped(sender:UITapGestureRecognizer) {
        if in_progress {
            return
        }
        startJobWithStartPoint(sender.locationInView(image_holder))
        in_progress = true
    }
    
    func iteration(sender:CADisplayLink) {
        if current_type == "prim" || current_type == "rand" {
            var iters = 0
            var rects_update:[(rect:CGRect,color:UIColor)] = []
            while iters < (current_type == "prim" ? PRIM_SPEED[current_speed] : RANDOM_SPEED[current_speed]) {
                if current_job_pixel.paused {
                    display_link.paused = true
                    in_progress = false
                    break
                }
                if current_type == "prim" {
                    if let draw_rect = (current_job_pixel as! PrimJob).nextCell() {
                        iters++
                        rects_update.append(draw_rect)
                    }
                }
                else {
                    if let draw_rect = (current_job_pixel as! RandomJob).nextCell() {
                        iters++
                        rects_update.append(draw_rect)
                    }
                }
            }
            updateImageWithRect(rects_update)
        }
        else {
            var points_add:[CAShapeLayer] = []
            var ovals_add:[(rect:CGRect,color:UIColor)] = []
            var c_speed = 0
            while ++c_speed < POISSON_SPEED[current_speed] {
                if let nextPoint = (current_job_layer as! PoissonJob).nextDraw() {
                    let layer = CAShapeLayer()
                    layer.frame = CGRect(x: nextPoint.center.x - current_job_layer.POINT_RAD, y: nextPoint.center.y - current_job_layer.POINT_RAD, width: current_job_layer.POINT_RAD * 2.0, height: current_job_layer.POINT_RAD * 2.0)
                    layer.path = UIBezierPath(ovalInRect: CGRect(x: 0, y: 0, width: current_job_layer.POINT_RAD * 2.0, height: current_job_layer.POINT_RAD * 2.0)).CGPath
                    layer.fillColor = nextPoint.color.CGColor
                    points_add.append(layer)
                    ovals_add.append((rect:layer.frame,color:nextPoint.color))
                }
                else {
                    if current_job_layer.paused {
                        display_link.paused = true
                        in_progress = false
                        break
                    }
                }
            }
            /*
            for layerAdd in points_add {
                draw_layer.addSublayer(layerAdd)
                layerAdd.removeAllAnimations()
                let anim = CABasicAnimation(keyPath: "opacity")
                anim.fromValue = 0.0
                anim.toValue = 1.0
                anim.duration = LAYER_ANIMATION_DURATION
                layerAdd.addAnimation(anim, forKey: "app")
            }
*/
            updateImageWithRect(ovals_add)
        }
    }
    
    func updateImageWithRect(rects:[(rect:CGRect,color:UIColor)]) {
        let ctx = UIGraphicsGetCurrentContext()
        for pixel in rects {
            CGContextSetFillColorWithColor(ctx, pixel.color.CGColor)
            if current_type == "poisson" {
                CGContextFillEllipseInRect(ctx, pixel.rect)
            }
            else {
               UIRectFill(pixel.rect)
            }
            
        }
        let img = UIGraphicsGetImageFromCurrentImageContext()
        image_holder.image = img
    }
    
}

class JobPixel : NSObject {
    
    let CELL_SIZE:CGFloat = 1
    var CELLS_TOTAL_WIDTH:Int = 0
    var CELLS_TOTAL_HEIGHT:Int = 0
    
    let COLOR_B_VALUE:CGFloat = 1.0
    let COLOR_S_VALUE:CGFloat = 1.0
    let COLOR_H_STEP:CGFloat = 0.001
    
    var paused = true
    var startPoint:CGPoint!
    var drawZone:CGRect!
    
    func startJob() {
        
    }
    
    init(drawZone:CGRect) {
        super.init()
        self.drawZone = drawZone
        
    }
    
    func randomWeight() -> CGFloat {
        return CGFloat(arc4random()) / CGFloat(UInt32.max)
    }
    
}

class JobLayer : NSObject {
    
    let POINTS_MIN_DISTANCE_RANGE:(CGFloat,CGFloat) = (8.0,13.0)
    let POINT_RAD:CGFloat = 2
    var POINTS_MIN_DISTANCE:CGFloat = 11
    let POISSON_LIMIT = 20
    let COLOR_HUE_STEP:CGFloat = 0.05
    let COLOR_SATURATION:CGFloat = 1.0
    let COLOR_BRIGHTNESS:CGFloat = 1.0
    
    var paused = false
    
    var drawLayer:CALayer!
    var startPoint:CGPoint!
    
    init(drawLayer:CALayer) {
        self.drawLayer = drawLayer
    }
    
    func startJob() {
        
    }
    
    func nextDraw() -> (center:CGPoint,color:UIColor)? {
        return nil
    }
    
    func getDist(p1:CGPoint,p2:CGPoint) -> CGFloat {
        let dx = p1.x - p2.x
        let dy = p1.y - p2.y
        return sqrt(dx * dx + dy * dy)
    }
    
    
    func randomCGFloatInRange(range:(CGFloat,CGFloat)) -> CGFloat {
        let fract = CGFloat(arc4random()) / CGFloat(UInt32.max)
        return (range.1 - range.0) * fract + range.0
    }
}


class PoissonJob : JobLayer {
    
    var CELLS_TOTAL_WIDTH:Int = 0
    var CELLS_TOTAL_HEIGHT:Int = 0
    var GRID_CELL_SIZE:CGFloat = 0
    var points:[CGPoint] = []
    var points_active:[CGPoint] = []
    var grid:[[CGPoint?]]!
    var dist_range:(CGFloat,CGFloat)!
    var angle_range:(CGFloat,CGFloat)!
    
    override func startJob() {
        UIGraphicsBeginImageContext(drawLayer.bounds.size)
        paused = false
        POINTS_MIN_DISTANCE = randomCGFloatInRange(POINTS_MIN_DISTANCE_RANGE)
        dist_range = (POINTS_MIN_DISTANCE, POINTS_MIN_DISTANCE * 2.0)
        angle_range = (0.0,6.27)
        GRID_CELL_SIZE = POINTS_MIN_DISTANCE * sqrt(2.0)
        CELLS_TOTAL_WIDTH = Int(drawLayer.bounds.width / GRID_CELL_SIZE)
        CELLS_TOTAL_HEIGHT = Int(drawLayer.bounds.height / GRID_CELL_SIZE)
        points = []
        points_active = []
        grid = Array(count: CELLS_TOTAL_WIDTH, repeatedValue: Array(count: CELLS_TOTAL_HEIGHT, repeatedValue: nil))
        let grid_point_x = min(Int(startPoint.x / GRID_CELL_SIZE) , CELLS_TOTAL_WIDTH - 1)
        let grid_point_y = min(Int(startPoint.y / GRID_CELL_SIZE) , CELLS_TOTAL_HEIGHT - 1)
        grid[grid_point_x][grid_point_y] = startPoint
        points.append(startPoint)
        points_active.append(startPoint)
    }
    
    override func nextDraw() -> (center:CGPoint,color:UIColor)? {
        if points_active.count == 0 {
            paused = true
            return nil
        }
        else {
            let rand_active_point_index = Int(arc4random_uniform(UInt32(points_active.count)))
            let rand_active_point = points_active[rand_active_point_index]
            var attempts = 0
            while ++attempts < POISSON_LIMIT {
                let rand_dist = randomCGFloatInRange(dist_range)
                let rand_angle = randomCGFloatInRange(angle_range)
                let dx = cos(rand_angle) * rand_dist
                let dy = sin(rand_angle) * rand_dist * -1.0
                let final_point = CGPoint(x: rand_active_point.x + dx, y: rand_active_point.y + dy)
                if final_point.x <= 0 || final_point.x >= drawLayer.bounds.width || final_point.y <= 0 || final_point.y >= drawLayer.bounds.height {
                    continue
                }
                let final_grid_point = CGPoint(x: min(Int(final_point.x / GRID_CELL_SIZE) , CELLS_TOTAL_WIDTH - 1), y: min(Int(final_point.y / GRID_CELL_SIZE) , CELLS_TOTAL_HEIGHT - 1))
                if checkValidAdjacentGridCellsForGridPoint(final_grid_point, finalPoint: final_point) {
                    points.append(final_point)
                    points_active.append(final_point)
                    grid[Int(final_grid_point.x)][Int(final_grid_point.y)] = final_point
                    let color_hue = COLOR_HUE_STEP * CGFloat(points.count) % 1.0
                    let color = UIColor(hue: color_hue, saturation: COLOR_SATURATION, brightness: COLOR_BRIGHTNESS, alpha: 1.0)
                    return (center:final_point,color:color)
                }
            }
            points_active[rand_active_point_index] = points_active[points_active.count - 1]
            points_active.removeLast()
            return nil
        }
    }
    
    func checkValidAdjacentGridCellsForGridPoint(gridPoint:CGPoint, finalPoint:CGPoint) -> Bool {
        var grid_cells_check:[CGPoint] = []
        let grid_point_x = Int(gridPoint.x)
        let grid_point_y = Int(gridPoint.y)
        if grid[grid_point_x][grid_point_y] != nil {
            return false
        }
        if grid_point_x >= 1 {
            grid_cells_check.append(CGPoint(x: gridPoint.x - 1, y: gridPoint.y))
            if grid_point_y >= 1 {
                grid_cells_check.append(CGPoint(x: gridPoint.x - 1, y: gridPoint.y - 1))
            }
            if grid_point_y < CELLS_TOTAL_HEIGHT - 1 {
                grid_cells_check.append(CGPoint(x: gridPoint.x - 1, y: gridPoint.y + 1))
            }
        }
        if grid_point_x < CELLS_TOTAL_WIDTH - 1 {
            grid_cells_check.append(CGPoint(x: gridPoint.x + 1, y: gridPoint.y))
            if grid_point_y >= 1 {
                grid_cells_check.append(CGPoint(x: gridPoint.x + 1, y: gridPoint.y - 1))
            }
            if grid_point_y < CELLS_TOTAL_HEIGHT - 1 {
                grid_cells_check.append(CGPoint(x: gridPoint.x + 1, y: gridPoint.y + 1))
            }
        }
        if grid_point_y >= 1 {
            grid_cells_check.append(CGPoint(x: gridPoint.x, y: gridPoint.y - 1))
        }
        if grid_point_y < CELLS_TOTAL_HEIGHT - 1 {
            grid_cells_check.append(CGPoint(x: gridPoint.x, y: gridPoint.y + 1))
        }
        for gridPointCheck in grid_cells_check {
            if let pointCheck = grid[Int(gridPointCheck.x)][Int(gridPointCheck.y)] {
                if getDist(pointCheck, p2: finalPoint) < POINTS_MIN_DISTANCE {
                    return false
                }
            }
        }
        return true
    }

}

class RandomJob : JobPixel {
    
    var array:[CGPoint] = []
    var used_cells:[Bool] = []
    var color_hue:CGFloat = 0.0
    var color_inc:Int = 0
    
    override init(drawZone: CGRect) {
        super.init(drawZone: drawZone)
        CELLS_TOTAL_WIDTH =  Int(drawZone.width / CELL_SIZE)
        CELLS_TOTAL_HEIGHT = Int(drawZone.height / CELL_SIZE)
    }
    
    override func startJob() {
        UIGraphicsBeginImageContext(drawZone.size)
        let start_point_x = Int(startPoint.x / CELL_SIZE)
        let start_point_y = Int(startPoint.y / CELL_SIZE)
        let start_point_index = start_point_y * CELLS_TOTAL_WIDTH + start_point_x
        self.startPoint = CGPoint(x: start_point_x, y: start_point_y)
        let start_cell:CGPoint = CGPoint(x: start_point_x, y: start_point_y)
        array = []
        array.reserveCapacity(65000)
        used_cells = Array(count: (CELLS_TOTAL_WIDTH + 1) * (CELLS_TOTAL_HEIGHT + 1), repeatedValue: false)
        used_cells[start_point_index] = true
        pushAdjacentCellsToCell(start_cell)
        paused = false
    }
    
    func pushRandomArray(cell:CGPoint) {
        let cell_index = Int(cell.y) * CELLS_TOTAL_WIDTH + Int(cell.x)
        if used_cells[cell_index] {
            return
        }
        array.append(cell)
    }
    
    func popRandomArray() -> CGPoint? {
        if array.count == 0 {
            return nil
        }
        else {
            let random_index = Int(arc4random_uniform(UInt32(array.count)))
            let ret_cell = array[random_index]
            array[random_index] = array[array.count - 1]
            array.removeLast()
            //
            return ret_cell
        }
    }
    
    func pushAdjacentCellsToCell(cell:CGPoint) {
        let cell_point_x = Int(cell.x)
        let cell_point_y = Int(cell.y)
        if cell_point_y >= 1 {
            let new_cell = CGPoint(x: cell_point_x, y: cell_point_y - 1)
            pushRandomArray(new_cell)
        }
        if cell_point_y < CELLS_TOTAL_HEIGHT {
            let new_cell = CGPoint(x: cell_point_x, y: cell_point_y + 1)
             pushRandomArray(new_cell)
        }
        if cell_point_x > 0 {
            let new_cell = CGPoint(x: cell_point_x - 1, y: cell_point_y)
             pushRandomArray(new_cell)
        }
        if cell_point_x < CELLS_TOTAL_WIDTH {
            let new_cell = CGPoint(x: cell_point_x + 1, y: cell_point_y)
             pushRandomArray(new_cell)
        }
    }
    
    func nextCell() -> (rect:CGRect,color:UIColor)? {
        let ret_cell = popRandomArray()
        if let cell = ret_cell {
            let cellIndex = Int(cell.y) * CELLS_TOTAL_WIDTH + Int(cell.x)
            if !used_cells[cellIndex] {
                used_cells[cellIndex] = true
                pushAdjacentCellsToCell(cell)
                if ++color_inc > 50 {
                    color_inc = 0
                    color_hue += COLOR_H_STEP
                    color_hue %= 1.0
                }
                let cellColor = UIColor(hue: color_hue, saturation: COLOR_S_VALUE, brightness: COLOR_B_VALUE, alpha: 1.0)
                return (CGRectMake(cell.x * CELL_SIZE, cell.y * CELL_SIZE, CELL_SIZE, CELL_SIZE) , cellColor)
            }
            return nil
        }
        else {
            paused = true
            print("FINISHED!!!")
            return nil
        }
    }
    
    
    
}

class PrimJob:JobPixel {
    
    var heap:[(cellPoint:CGPoint,weight:CGFloat)] = []
    var used_cells:[Bool] = []
    var color_hue:CGFloat = 0.0
    var color_inc:Int = 0
    
    override init(drawZone: CGRect) {
        super.init(drawZone: drawZone)
        CELLS_TOTAL_WIDTH =  Int(drawZone.width / CELL_SIZE)
        CELLS_TOTAL_HEIGHT = Int(drawZone.height / CELL_SIZE)
    }
    
    
    override func startJob() {
        UIGraphicsBeginImageContext(drawZone.size)
        heap = []
        heap.reserveCapacity(65000)
        let rand_cell:(cellPoint:CGPoint,weight:CGFloat) = (cellPoint:CGPointMake(-1, -1),weight: -1.0)
        heap.append(rand_cell)
        used_cells = Array(count: (CELLS_TOTAL_WIDTH + 1) * (CELLS_TOTAL_HEIGHT + 1), repeatedValue: false)
        let start_point_x = Int(startPoint.x / CELL_SIZE)
        let start_point_y = Int(startPoint.y / CELL_SIZE)
        let start_point_index = start_point_y * CELLS_TOTAL_WIDTH + start_point_x
        self.startPoint = CGPoint(x: start_point_x, y: start_point_y)
        used_cells[start_point_index] = true
        let start_cell:(cellPoint:CGPoint, weight:CGFloat) = (CGPoint(x: start_point_x, y: start_point_y), 1.0)
        pushAdjacentCellsToCell(start_cell)
        paused = false
    }
    
    func pushHeapWithCell(cell:(cellPoint:CGPoint,weight:CGFloat)) {
        let cell_index = Int(cell.cellPoint.y) * CELLS_TOTAL_WIDTH + Int(cell.cellPoint.x)
        if used_cells[cell_index] {
            return
        }
        heap.append(cell)
        var i:Int = (heap.count - 1) / 2 , j = heap.count - 1
        while i > 0 {
            if heap[i].weight > cell.weight {
                swap(&heap[i], &heap[j])
                j = i
                i /= 2
            }
            else {
                break
            }
            
        }
    }
    
    func popHeap() -> (cellPoint:CGPoint,weight:CGFloat) {
        if heap.count == 1 {
            return (CGPointMake(-1, -1),-1)
        }
        else {
            var i = 1, min_ind = 2
            let ret_cell = heap[1]
            heap[1] = heap[heap.count - 1]
            heap.removeLast()
            while i < heap.count - 1 {
                min_ind = -1
                if i * 2 < heap.count - 1 && heap[i].weight > heap[i * 2].weight {
                    min_ind = i * 2
                }
                if i * 2 + 1 < heap.count - 1 && heap[i].weight > heap[i * 2 + 1].weight {
                    if (min_ind != -1 && heap[i * 2 + 1].weight < heap[i * 2].weight) || min_ind == -1 {
                        min_ind = i * 2 + 1
                    }
                }
                if min_ind == -1 {
                    break
                }
                else {
                    swap(&heap[i], &heap[min_ind])
                    i = min_ind
                }
            }
            return ret_cell
        }
    }
    
    func nextCell() -> (rect:CGRect,color:UIColor)? {
        let cell = popHeap()
        if cell.weight == -1 {
            paused = true
            print("FINISHED!!!")
            return nil
        }
        else {
            let cellPoint = cell.cellPoint
            let cellIndex = Int(cellPoint.y) * CELLS_TOTAL_WIDTH + Int(cellPoint.x)
            if !used_cells[cellIndex] {
                used_cells[cellIndex] = true
                pushAdjacentCellsToCell(cell)
                
                if ++color_inc > 50 {
                    color_inc = 0
                    color_hue += COLOR_H_STEP
                    color_hue %= 1.0
                }
                /*
                let d_x = cell.cellPoint.x - startPoint.x
                let d_y = cell.cellPoint.y - startPoint.y
                let color_hue = sqrt(d_x * d_x + d_y * d_y) % DIST_MOD / DIST_MOD
                */
                let cellColor = UIColor(hue: color_hue, saturation: COLOR_S_VALUE, brightness: COLOR_B_VALUE, alpha: 1.0)
                return (CGRectMake(cellPoint.x * CELL_SIZE, cellPoint.y * CELL_SIZE, CELL_SIZE, CELL_SIZE) , cellColor)
                /*
                let cellLayer = CALayer()
                cellLayer.frame = CGRect(x: cellPoint.x * CELL_SIZE, y: cellPoint.y * CELL_SIZE, width: CELL_SIZE, height: CELL_SIZE)
                
                cellLayer.backgroundColor = cellColor
                view.layer.addSublayer(cellLayer)
                */
                //let cellAnim = CABasicAnimation(keyPath: "opacity")
                //cellAnim.fromValue = 0.0
                //cellAnim.toValue = 1.0
                // cellAnim.duration = CELL_ANIMATION_DURATION
                // cellLayer.addAnimation(cellAnim, forKey: "opaci")
                // total_l_time += (CACurrentMediaTime() - l_beg)
            }
            return nil
        }
    }
    
    func pushAdjacentCellsToCell(cell:(cellPoint:CGPoint,weight:CGFloat)) {
        let cell_point_x = Int(cell.cellPoint.x)
        let cell_point_y = Int(cell.cellPoint.y)
        if cell_point_y >= 1 {
            let new_cell = (CGPoint(x: cell_point_x, y: cell_point_y - 1), randomWeight())
            pushHeapWithCell(new_cell)
            //print(new_cell)
        }
        if cell_point_y < CELLS_TOTAL_HEIGHT {
            let new_cell = (CGPoint(x: cell_point_x, y: cell_point_y + 1), randomWeight())
            pushHeapWithCell(new_cell)
            //print(new_cell)
        }
        if cell_point_x > 0 {
            let new_cell = (CGPoint(x: cell_point_x - 1, y: cell_point_y), randomWeight())
            pushHeapWithCell(new_cell)
            //print(new_cell)
        }
        if cell_point_x < CELLS_TOTAL_WIDTH {
            let new_cell = (CGPoint(x: cell_point_x + 1, y: cell_point_y), randomWeight())
            pushHeapWithCell(new_cell)
            // print(new_cell)
        }
    }
    
    

}

