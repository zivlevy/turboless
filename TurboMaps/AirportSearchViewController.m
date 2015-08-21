//
//  AirportSearchViewController.m
//  TurboMaps
//
//  Created by Ziv Levy on 8/19/15.
//  Copyright (c) 2015 ZivApps. All rights reserved.
//

#import "AirportSearchViewController.h"
#import "RouteManager.h"
#import "Const.h"
#import "Helpers.h"
#import "Airport.h"

@interface AirportSearchViewController()<UITableViewDataSource, UITableViewDelegate,UISearchControllerDelegate,UISearchBarDelegate,UISearchResultsUpdating>
@property (weak, nonatomic) IBOutlet UITableView *tableVIew;

@property (nonatomic,strong) NSArray * airports;
@property (nonatomic,strong) NSArray * searchResults;

@property (strong, nonatomic) UISearchController *searchController;

@end
@implementation AirportSearchViewController

-(void) viewDidLoad
{
    [super viewDidLoad];

    NSSortDescriptor *ageDescriptor = [[NSSortDescriptor alloc] initWithKey:@"ICAO" ascending:YES];
    NSArray *sortDescriptors = @[ageDescriptor];
    _airports = [[[RouteManager sharedManager] getAirports] sortedArrayUsingDescriptors:sortDescriptors];
    
    _tableVIew.delegate = self;
    _tableVIew.dataSource = self;
    
    self.view.backgroundColor = kColorToolbarBackground;
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.delegate   = self;
    
    self.searchController.searchBar.delegate  = self;
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;

    self.tableVIew.tableHeaderView = self.searchController.searchBar;
        self.definesPresentationContext = YES;
    [self.searchController.searchBar sizeToFit];

}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];


    self.searchController.searchBar.tintColor = kColorToolbarBackground;
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 100 ), dispatch_get_main_queue(), ^{

        [self.searchController.searchBar becomeFirstResponder];

    });
    
}
#pragma mark - table view delegates

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.searchController.active)
    {
        return [self.searchResults count];
    }
    else {
        return _airports.count;
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{



        Airport * selectedAirport;
        if (self.searchController.active)
        {
            selectedAirport = self.searchResults [indexPath.row];
            
        }
        else {
            selectedAirport = _airports [indexPath.row];
            
        }
        [self.delegate airportSelected: selectedAirport toTargetControl:_taragetControl ];
        NSLog(@"%@",selectedAirport.ICAO);

}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    Airport * airport ;
    if (self.searchController.active)
    {
        airport = _searchResults[indexPath.row];
    }else {
        
        airport = _airports[indexPath.row];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"%@ / %@",airport.ICAO ,airport.symbol];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@",airport.name ,airport.city];
    
 
    return cell;
    
}


#pragma mark search delegate

- (void)didPresentSearchController:(UISearchController *)searchController
{
    
}
-(void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    [self filterAirportsForSearchText: searchController.searchBar.text];
    [_tableVIew reloadData];
}


- (void) filterAirportsForSearchText:(NSString *) searchText
{
    _searchResults = [[RouteManager sharedManager]getAirportsBySymbols:searchText];
    
}

- (void)searchBar:(UISearchBar *)searchBar selectedScopeButtonIndexDidChange:(NSInteger)selectedScope
{
    [self updateSearchResultsForSearchController:self.searchController];
}
@end
