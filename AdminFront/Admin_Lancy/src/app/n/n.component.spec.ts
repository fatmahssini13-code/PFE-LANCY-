import { ComponentFixture, TestBed } from '@angular/core/testing';

import { NComponent } from './n.component';

describe('NComponent', () => {
  let component: NComponent;
  let fixture: ComponentFixture<NComponent>;

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [NComponent]
    });
    fixture = TestBed.createComponent(NComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
