import { ComponentFixture, TestBed } from '@angular/core/testing';

import { EscrowManagementComponent } from './escrow-management.component';

describe('EscrowManagementComponent', () => {
  let component: EscrowManagementComponent;
  let fixture: ComponentFixture<EscrowManagementComponent>;

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [EscrowManagementComponent]
    });
    fixture = TestBed.createComponent(EscrowManagementComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
